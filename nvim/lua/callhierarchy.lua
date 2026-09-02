-- Call hierarchy, rendered through fzf-lua.
--
-- nvim's built-in vim.lsp.buf.incoming_calls dumps one level into the quickfix
-- list. That answers "who calls this" but not "how is this reached", which
-- needs the level above, and the one above that.
--
-- fzf is a filter over a fixed list, so it cannot expand nodes on demand.
-- Instead the tree is walked to MAX_DEPTH up front and handed over flattened
-- and indented. You lose interactive expansion; you gain fuzzy search across
-- the whole hierarchy at once, and the picker, preview window, keybindings and
-- muscle memory are the ones already used everywhere else here.
--
-- Static analysis: a call made through a function pointer registered at
-- runtime is invisible, so a branch ends at whatever installs the callback.
-- In firmware that happens often. It is a property of the question, not a bug.

local M = {}

-- Each level costs one LSP round trip per node, so both of these are about
-- keeping a wide tree from turning into hundreds of requests.
local MAX_DEPTH = 4
local MAX_NODES = 250
-- Each bridge makes clangd build an AST for a file it has not parsed (~470ms),
-- so the number of them is the thing that decides whether this feels instant.
local MAX_BRIDGES = 5

-- ---------------------------------------------------------------------------
-- Bridging indirect calls through an ops-struct field.
--
-- C dispatch tables defeat static call hierarchy: the language server sees
--
--     const struct driver_ops ops = { .connect = tcp_connect };
--
-- and separately
--
--     ctx->ops->connect(ctx, ...);
--
-- but nothing links them, so a hierarchy ends at whatever registers the table.
-- This bridges the two by name: find the field a function is assigned to, then
-- find calls through that field, then resume the ordinary hierarchy from the
-- functions containing those calls.
--
-- It is a GUESS. It goes wrong when two unrelated structs share a field name,
-- when the assignment is not a designated initialiser, or when the pointer is
-- copied into a local first. Bridged rows are marked so a guess never passes
-- for something the compiler actually knows.
-- ---------------------------------------------------------------------------

-- Files opened purely to ask the language server about them.
--
-- Loading a buffer sends didOpen, and the server then builds and RETAINS an
-- AST for that translation unit. A deep traversal touches many files, so
-- holding them all is a genuine leak: on a unit whose macros expand hugely it
-- is enough to exhaust memory and get the server killed, which then leaves
-- swap files behind and breaks even go-to-definition.
--
-- So: remember which buffers this module created, and wipe those -- and only
-- those -- when the traversal finishes. Buffers the user already had open are
-- left alone.
local loaded = {}
local created = {}

local function load_buf(path)
  if loaded[path] then
    return loaded[path]
  end
  local existing = vim.fn.bufnr(path)
  local bufnr = vim.fn.bufadd(path)
  -- A file another nvim has open would otherwise stop on the "found a swap
  -- file" prompt, mid-traversal, with nobody there to answer it. These buffers
  -- are only ever read.
  vim.bo[bufnr].swapfile = false
  local was_loaded = vim.api.nvim_buf_is_loaded(bufnr)
  vim.fn.bufload(bufnr)
  loaded[path] = bufnr
  if existing == -1 and not was_loaded then
    created[bufnr] = true
  end
  return bufnr
end

-- Hand the translation units back to the language server. Anything visible in
-- a window is left alone, in case a jump landed there.
local function release_buffers()
  local visible = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(w)] = true
  end
  for bufnr in pairs(created) do
    if vim.api.nvim_buf_is_valid(bufnr) and not visible[bufnr] then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true, unload = false })
    end
  end
  created = {}
  loaded = {}
end

-- The function containing a given line, found by reading the buffer.
--
-- documentSymbol answers this exactly, but costs ~470ms the first time clangd
-- sees a file because it has to build an AST -- and it was 5 such calls, most
-- of this feature's runtime. bufload is 10ms and prepareCallHierarchy is ~1ms,
-- so scanning the text and asking about one position instead is far cheaper.
--
-- Heuristic, hence the brace check and the documentSymbol fallback below: a
-- definition starts in column 0, has a parameter list, and does not end in a
-- semicolon (that would be a prototype). Whether the target line is actually
-- inside it is then confirmed by counting braces, so a site sitting between
-- two functions is rejected rather than attributed to the one above it.
local function enclosing_by_text(bufnr, lnum)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lnum, false)
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line:match("^[%a_][%w_%s%*]*[%w_%*]%s*%(")
      and not line:match(";%s*$")
      and not line:match("^#")
    then
      local depth = 0
      for j = i, #lines do
        local _, o = lines[j]:gsub("{", "")
        local _, c = lines[j]:gsub("}", "")
        depth = depth + o - c
      end
      -- Still inside the body at the target line.
      if depth > 0 then
        local name = line:match("([%a_][%w_]*)%s*%(")
        local col = name and line:find(name .. "%s*%(")
        if name and col then
          return { line = i - 1, character = col - 1 }
        end
      end
      return nil
    end
  end
end

local function enclosing_item(client, path, lnum)
  local bufnr = load_buf(path)

  local function prepare(pos)
    local prep = vim.lsp.buf_request_sync(bufnr, "textDocument/prepareCallHierarchy", {
      textDocument = { uri = vim.uri_from_bufnr(bufnr) },
      position = pos,
    }, 5000)
    for _, v in pairs(prep or {}) do
      if v.result and v.result[1] then
        return v.result[1]
      end
    end
  end

  local pos = enclosing_by_text(bufnr, lnum)
  if pos then
    local item = prepare(pos)
    if item then
      return item
    end
  end

  -- Fallback: ask clangd properly. Correct, and slow enough that it is worth
  -- avoiding, but the text scan cannot cope with every formatting style.
  local res = vim.lsp.buf_request_sync(
    bufnr,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params(bufnr) },
    5000
  )
  local best
  local function scan(symbols)
    for _, s in ipairs(symbols or {}) do
      local r = s.range
      if r and r.start.line <= lnum - 1 and r["end"].line >= lnum - 1 then
        -- 12 = Function, 6 = Method
        if s.kind == 12 or s.kind == 6 then
          best = s
        end
        scan(s.children)
      end
    end
  end
  for _, v in pairs(res or {}) do
    scan(v.result)
  end
  if best then
    return prepare(best.selectionRange.start)
  end
end

-- ---------------------------------------------------------------------------
-- Indirect-call patterns.
--
-- C has several ways to call a function without naming it, and they need
-- different treatment. Each entry below takes a function and returns the
-- places that reach it indirectly. Adding a shape means adding an entry.
--
-- Only the ops/vtable shape is implemented, because it is the only one this
-- codebase uses: a listener is a struct of named function pointers registered
-- into a list, which is the same shape as a driver ops table. A bare function
-- pointer handed to a registrar and stored in an array would need its own
-- entry -- there is no shared symbol linking registration to dispatch, only an
-- assignment inside the registrar body.
-- ---------------------------------------------------------------------------

local refs_cache = {}
local function refs_at(bufnr, pos)
  local key = vim.uri_from_bufnr(bufnr) .. ":" .. pos.line .. ":" .. pos.character
  if refs_cache[key] then
    return refs_cache[key]
  end
  local r = vim.lsp.buf_request_sync(bufnr, "textDocument/references", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = pos,
    context = { includeDeclaration = false },
  }, 5000)
  local acc = {}
  for _, v in pairs(r or {}) do
    vim.list_extend(acc, v.result or {})
  end
  refs_cache[key] = acc
  return acc
end

local function def_at(bufnr, line, col)
  local d = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = col },
  }, 5000)
  for _, v in pairs(d or {}) do
    local r = (v.result or {})[1]
    if r then
      return vim.uri_to_fname(r.uri or r.targetUri), (r.range or r.targetSelectionRange)
    end
  end
end

local function line_at(bufnr, lnum)
  return (vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false) or {})[1] or ""
end

-- PATTERN 1: ops struct / vtable.
--
--     struct driver_ops ops = { .connect = tcp_connect };   -- registration
--     ctx->ops->connect(ctx, ...);                          -- dispatch
--
-- Both ends reference the same field DECLARATION, so one typed lookup links
-- them: clangd returns uses of driver_ops::connect only, never another
-- struct's connect. It sees through the preprocessor too, so a table reached
-- via a #define inside a macro is found where text search finds nothing.
--
-- Dispatch is NOT required to look like "->connect(". A macro that generates
-- the dispatcher writes the field name only as a macro argument -- the call
-- itself says "_var->_event(...)" -- so anything that is not a registration is
-- treated as a candidate, and resolving its enclosing function decides.
local function pattern_ops(item, bufnr)
  local out = {}
  local start = item.selectionRange and item.selectionRange.start
  if not start then
    return out
  end
  for _, ref in ipairs(refs_at(bufnr, start)) do
    local rb = load_buf(vim.uri_to_fname(ref.uri))
    local lnum = ref.range.start.line
    local line = line_at(rb, lnum)
    local field = line:match("[%.>]%s*([%w_]+)%s*=%s*" .. vim.pesc(item.name))
    local col = field and line:find("[%.>]" .. field)
    if col then
      local dpath, drange = def_at(rb, lnum, col)
      if dpath then
        local db = load_buf(dpath)
        for _, use in ipairs(refs_at(db, drange.start)) do
          local upath = vim.uri_to_fname(use.uri)
          local ub = load_buf(upath)
          local ul = use.range.start.line
          -- Everything except the registrations themselves.
          if not line_at(ub, ul):match("[%.>]%s*" .. field .. "%s*=") then
            table.insert(out, { path = upath, lnum = ul + 1, label = "->" .. field })
          end
        end
      end
    end
  end
  return out
end

local PATTERNS = { pattern_ops }

local function indirect_callers(item, bufnr)
  local out, seen = {}, {}
  for _, find in ipairs(PATTERNS) do
    local ok, sites = pcall(find, item, bufnr)
    if ok then
      for _, s in ipairs(sites) do
        local k = s.path .. ":" .. s.lnum
        if not seen[k] then
          seen[k] = true
          table.insert(out, s)
        end
      end
    end
  end
  return out
end

-- The implementations behind a field dispatch, e.g. "ops->connect(...)".
--
-- Mirror of indirect_callers. clangd's outgoingCalls omits indirect calls
-- entirely -- it reports only the direct callees, never the dispatch through
-- ops -- so the call site has to be found by
-- reading the body, and then:
--
--   definition at the field    -> "int (*connect)(...)"
--   references to that decl    -> ".connect = tcp_connect"
--
-- The assignments are the implementations. Typed, so a field of the same name
-- on another struct does not appear, and macro-aware, so a table registered
-- through "#define platform_mdi_ops ..." is still found.
local function implementations_of(bufnr, lnum, col, field)
  local out = {}
  local defs = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = lnum, character = col },
  }, 5000)
  for _, v in pairs(defs or {}) do
    local d = (v.result or {})[1]
    if d then
      local drange = d.range or d.targetSelectionRange
      local db = load_buf(vim.uri_to_fname(d.uri or d.targetUri))
      -- Cheap filter before the expensive part. Most "x->y(" in a body are
      -- ordinary calls whose definition is a function, not a function-pointer
      -- member; running references (~175ms) on each of those was most of the
      -- cost of the outgoing direction.
      local dline = (vim.api.nvim_buf_get_lines(db, drange.start.line, drange.start.line + 1, false) or {})[1] or ""
      if not dline:match("%(%s*%*%s*" .. field .. "%s*%)") then
        goto continue
      end
      local key = (d.uri or d.targetUri) .. ":" .. drange.start.line
      local uses = refs_cache[key]
      if not uses then
        uses = {}
        local r = vim.lsp.buf_request_sync(db, "textDocument/references", {
          textDocument = { uri = vim.uri_from_bufnr(db) },
          position = drange.start,
          context = { includeDeclaration = false },
        }, 5000)
        for _, vv in pairs(r or {}) do
          vim.list_extend(uses, vv.result or {})
        end
        refs_cache[key] = uses
      end
      for _, use in ipairs(uses) do
        local upath = vim.uri_to_fname(use.uri)
        local ub = load_buf(upath)
        local ul = use.range.start.line
        local uline = (vim.api.nvim_buf_get_lines(ub, ul, ul + 1, false) or {})[1] or ""
        -- A designated initialiser is a registration; anything else is a call.
        local impl = uline:match("%.%s*" .. field .. "%s*=%s*([%w_]+)")
        if impl then
          -- ".connect = tcp_connect" contains the name twice;
          -- the one that matters is the value, after the '='.
          local eq = uline:find("=")
          local icol = eq and uline:find(impl, eq, true)
          table.insert(out, { name = impl, path = upath, lnum = ul + 1, col = icol and icol - 1 or 0 })
        end
      end
    end
    ::continue::
  end
  return out
end


-- The CallHierarchyItem for the symbol written at a position: follow its
-- definition, then prepare a hierarchy item there.
local function item_at_symbol(path, lnum, col)
  local b = load_buf(path)
  local defs = vim.lsp.buf_request_sync(b, "textDocument/definition", {
    textDocument = { uri = vim.uri_from_bufnr(b) },
    position = { line = lnum - 1, character = col },
  }, 5000)
  for _, v in pairs(defs or {}) do
    local d = (v.result or {})[1]
    if d then
      local db = load_buf(vim.uri_to_fname(d.uri or d.targetUri))
      local r = d.range or d.targetSelectionRange
      local prep = vim.lsp.buf_request_sync(db, "textDocument/prepareCallHierarchy", {
        textDocument = { uri = vim.uri_from_bufnr(db) },
        position = r.start,
      }, 5000)
      for _, vv in pairs(prep or {}) do
        if vv.result and vv.result[1] then
          return vv.result[1]
        end
      end
    end
  end
end

-- Field dispatches inside a function body: "x->field(" / "x.field(".
local function dispatches_in(bufnr, range)
  local out = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, range.start.line, range["end"].line + 1, false)
  for i, line in ipairs(lines) do
    for field in line:gmatch("[%->%.]([%w_]+)%s*%(") do
      local col = line:find("[%->%.]" .. field .. "%s*%(")
      if col then
        table.insert(out, { lnum = range.start.line + i - 1, col = col, field = field })
      end
    end
  end
  return out
end

local function client_for(bufnr)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if c.server_capabilities.callHierarchyProvider then
      return c
    end
  end
end

-- Walk the direct call hierarchy and hand back flattened rows IN TREE ORDER.
--
-- The requests are async and complete in arbitrary order, so responses cannot
-- be appended to a flat list as they arrive: branches interleave and a node
-- ends up displayed under a parent that does not call it. Build a real tree
-- first, flatten it depth-first once everything has landed.
--
-- No bridging here. Direct calls cost ~18ms a node because incomingCalls is
-- answered from clangd's index; bridging costs ~470ms a node because it makes
-- clangd build an AST for a file it has not parsed. Keeping them apart is what
-- lets the direct half reach the screen immediately.
local function walk_direct(client, root, direction, indent, bridge, done)
  local method = direction == "incoming" and "callHierarchy/incomingCalls"
    or "callHierarchy/outgoingCalls"
  local pending, count, seen = 0, 0, {}

  local function key(item)
    return item.uri .. ":" .. item.name
  end

  local leaves = {}

  local function finish()
    local rows = {}
    local function flatten(n, depth)
      local range = n.ranges[1] or n.item.selectionRange or n.item.range
      local path = vim.uri_to_fname(n.item.uri)
      local lnum = (range and range.start.line or 0) + 1
      local arrow = direction == "incoming" and "\u{2190} " or "\u{2192} "
      rows[#rows + 1] = {
        left = string.rep("  ", depth + indent)
          .. ((depth > 0 or indent > 0) and arrow or "")
          .. n.item.name
          .. (n.bridge and (" [via " .. n.bridge .. "]") or ""),
        right = vim.fn.fnamemodify(path, ":t") .. ":" .. lnum,
        path = path,
        lnum = lnum,
        col = (range and range.start.character or 0) + 1,
      }
      -- A node needs bridging when nothing CALLS it, which is not the same as
      -- having no children. clangd reports the ops-table initialiser
      -- (".connect = tcp_connect") as an incoming call, so a registered function
      -- always has a child -- a variable, not a caller. Counting those as
      -- callers made the chain dead-end in the very table the bridge exists to
      -- cross.
      local callers, registered = 0, false
      for _, c in ipairs(n.children) do
        -- 12 = Function, 6 = Method. Anything else is data.
        if c.item.kind == 12 or c.item.kind == 6 then
          -- ...and it has to actually CALL, not merely mention. A function
          -- passed to a registrar -- "add_listener(on_change)" -- is reported
          -- as an incoming call from the registering function, which is a
          -- reference, not a call. Counting it made the node look like it had
          -- callers, so the bridge never ran on exactly the registrations it
          -- exists to follow. Reading the call site settles it: a real call
          -- writes the name followed by an open paren.
          local calls = false
          for _, r in ipairs(c.ranges or {}) do
            local ok, cb = pcall(load_buf, vim.uri_to_fname(c.item.uri))
            if ok then
              local l = (vim.api.nvim_buf_get_lines(cb, r.start.line, r.start.line + 1, false) or {})[1] or ""
              if l:match("%f[%w_]" .. vim.pesc(n.item.name) .. "%f[^%w_]%s*%(") then
                calls = true
              end
            end
          end
          if calls or #(c.ranges or {}) == 0 then
            callers = callers + 1
          else
            -- Referenced without being called: its address was taken, which
            -- means it was registered somewhere.
            registered = true
          end
        else
          -- A non-function "caller" is a table the function was put into.
          registered = true
        end
      end
      -- Bridge when the chain has stopped OR when the function is registered
      -- somewhere, because both can be true at once: a function can be called
      -- directly AND installed as a callback, and only following both gives
      -- the whole picture. Ordinary functions trip neither test and cost
      -- nothing.
      if callers == 0 or registered then
        leaves[#leaves + 1] = { node = n, row = #rows, depth = depth + indent }
      end
      for _, c in ipairs(n.children) do
        flatten(c, depth + 1)
      end
    end
    flatten(root, 0)
    done(rows, leaves)
  end

  local function visit(node, depth)
    count = count + 1
    if depth >= MAX_DEPTH or count >= MAX_NODES or seen[key(node.item)] then
      return
    end
    seen[key(node.item)] = true
    pending = pending + 1
    client:request(method, { item = node.item }, function(err, result)
      if not err and result then
        local root_dir = client.root_dir or vim.fn.getcwd()
        for _, call in ipairs(result) do
          local it = call.from or call.to
          local child = {
            item = it,
            ranges = call.fromRanges or {},
            children = {},
          }
          table.insert(node.children, child)
          -- Recursing into system headers means an AST build for string.h to
          -- learn what memcpy calls. Show the edge, do not follow it.
          if vim.startswith(vim.uri_to_fname(it.uri), root_dir) then
            visit(child, depth + 1)
          end
        end
      end
      -- Outgoing needs the mirror treatment, and cannot reuse the leaf trick:
      -- clangd omits indirect calls from outgoingCalls entirely, so there is
      -- no callee node to hang a bridge on. Read the body instead, find the
      -- field dispatches, and resolve each to what is registered there.
      if bridge and direction == "outgoing" and node.item.range then
        local nb = load_buf(vim.uri_to_fname(node.item.uri))
        for _, d in ipairs(dispatches_in(nb, node.item.range)) do
          for _, impl in ipairs(implementations_of(nb, d.lnum, d.col, d.field)) do
            -- The registration sits at file scope inside a struct initialiser,
            -- so there is no enclosing function to ask about. Resolve the name
            -- written there to the function it refers to instead.
            local it = item_at_symbol(impl.path, impl.lnum, impl.col)
            if it then
              table.insert(node.children, {
                item = it,
                ranges = {},
                children = {},
                bridge = d.field,
              })
              visit(node.children[#node.children], depth + 1)
            end
          end
        end
      end

      pending = pending - 1
      if pending == 0 then
        finish()
      end
    end)
  end

  visit(root, 0)
  if pending == 0 then
    finish()
  end
end

-- Format rows into the "path:line:col:text" entries fzf-lua's builtin
-- previewer parses, with the filenames padded into a column.
local function to_entries(rows)
  local width = 0
  for _, r in ipairs(rows) do
    width = math.max(width, vim.fn.strdisplaywidth(r.left))
  end
  width = math.min(width, 70)
  local out = {}
  for _, r in ipairs(rows) do
    local pad = math.max(1, width - vim.fn.strdisplaywidth(r.left) + 2)
    out[#out + 1] = string.format("%s:%d:%d:%s%s%s",
      vim.fn.fnamemodify(r.path, ":."), r.lnum, r.col,
      r.left, string.rep(" ", pad), r.right)
  end
  return out
end

---@param direction "incoming"|"outgoing"
---@param bridge boolean|nil  follow ops-struct dispatch as well
function M.open(direction, bridge)
  direction = direction or "incoming"
  local bufnr = vim.api.nvim_get_current_buf()
  local client = client_for(bufnr)
  if not client then
    vim.notify("No language server here supports call hierarchy", vim.log.levels.WARN)
    return
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request("textDocument/prepareCallHierarchy", params, function(err, result)
    if err or not result or not result[1] then
      vim.notify("No callable symbol under the cursor", vim.log.levels.WARN)
      return
    end
    local first = result[1]

    vim.schedule(function()
      local fzf = require("fzf-lua")
      -- Streamed: the picker opens at once and rows arrive as they resolve.
      -- Direct callers are index-answered and land in ~100ms; bridged ones
      -- need an AST per file and follow behind.
      fzf.fzf_exec(function(cb)
        local function finished()
          release_buffers()
          cb()
        end

        local function emit(rows)
          for _, e in ipairs(to_entries(rows)) do
            cb(e)
          end
        end

        walk_direct(client, { item = first, ranges = {}, children = {} }, direction, 0, bridge,
          function(rows, leaves)
            emit(rows)
            if not (bridge and direction == "incoming") then
              finished()
              return
            end
            -- Bridge only where the chain has actually stopped. A node with
            -- real callers is better followed directly, and each bridge costs
            -- an AST parse, so spending them on nodes that did not need one is
            -- what put this over budget.
            local budget = MAX_BRIDGES
            local queue = vim.deepcopy(leaves)
            local function step()
              local leaf = table.remove(queue, 1)
              if not leaf or budget <= 0 then
                if leaf and budget <= 0 then
                  cb(string.format("%s:1:1:%s[%d more leaves not followed: bridge budget]",
                    vim.uri_to_fname(first.uri), string.rep("  ", 1), #queue + 1))
                end
                finished()
                return
              end
              local nb = load_buf(vim.uri_to_fname(leaf.node.item.uri))
              local sites = indirect_callers(leaf.node.item, nb)
              if #sites == 0 then
                return step()
              end
              budget = budget - 1
              local remaining = #sites
              if remaining == 0 then
                return step()
              end
              for _, site in ipairs(sites) do
                local it = enclosing_item(client, site.path, site.lnum)
                if it then
                  walk_direct(client,
                    { item = it, ranges = { { start = { line = site.lnum - 1, character = 0 } } },
                      children = {}, bridge = site.label },
                    direction, leaf.depth + 1, false,
                    function(rows2)
                      emit(rows2)
                      remaining = remaining - 1
                      if remaining == 0 then
                        step()
                      end
                    end)
                else
                  remaining = remaining - 1
                  if remaining == 0 then
                    step()
                  end
                end
              end
            end
            step()
          end)
      end, {
        prompt = bridge and "Call hierarchy (ops)> "
          or (direction == "incoming" and "Who calls this> " or "This calls> "),
        previewer = "builtin",
        fzf_opts = {
          ["--no-sort"] = "",
          ["--tiebreak"] = "index",
          ["--delimiter"] = ":",
          ["--with-nth"] = "4..",
          ["--nth"] = "4..",
        },
        actions = require("fzf-lua.config").globals.actions.files,
      })
    end)
  end, bufnr)
end

-- The other direction, standalone. Standing on "ops->connect(...)",
-- gd only reaches the field declaration, because that is all the compiler
-- knows. This lists what is assigned to that field anywhere in the tree.
function M.implementations()
  local field = vim.fn.expand("<cword>")
  if field == "" then
    vim.notify("No field name under the cursor", vim.log.levels.WARN)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local impls = implementations_of(bufnr, pos[1] - 1, pos[2], field)
  if #impls == 0 then
    vim.notify("Nothing is assigned to ." .. field, vim.log.levels.INFO)
    return
  end
  local width = 0
  for _, i in ipairs(impls) do
    width = math.max(width, #i.name)
  end
  local entries = {}
  for _, i in ipairs(impls) do
    entries[#entries + 1] = string.format("%s:%d:1:%s%s  registered as .%s",
      vim.fn.fnamemodify(i.path, ":."), i.lnum, i.name,
      string.rep(" ", width - #i.name + 2), field)
  end
  require("fzf-lua").fzf_exec(entries, {
    prompt = "Implementations of ." .. field .. "> ",
    previewer = "builtin",
    fzf_opts = {
      ["--no-sort"] = "", ["--tiebreak"] = "index",
      ["--delimiter"] = ":", ["--with-nth"] = "4..", ["--nth"] = "4..",
    },
    actions = require("fzf-lua.config").globals.actions.files,
  })
end

return M
