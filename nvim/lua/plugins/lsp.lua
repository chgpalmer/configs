-- Language servers + completion.
--
-- clangd reads compile_commands.json, located via a .clangd file at the
-- project root. That is the same compilation database VSCode's clangd
-- extension consumes. pyright is the open core that VSCode's Pylance wraps.
--
-- Neither server is installed by a plugin manager: they are ordinary binaries
-- expected on PATH. Distro packages are often far too old, so prefer upstream
-- releases dropped in /usr/local or ~/.local.

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.lsp.config("clangd", {
        capabilities = capabilities,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=never", -- do not auto-add #includes
          "--completion-style=detailed",
          "--pch-storage=memory",
          "-j=8",
        },
        -- Stop clangd walking up past the repo root looking for a project.
        root_markers = { "compile_commands.json", ".clangd", ".git" },
      })

      vim.lsp.config("pyright", {
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              diagnosticMode = "openFilesOnly", -- workspace mode is slow on big trees
              useLibraryCodeForTypes = true,
            },
          },
        },
      })

      vim.lsp.enable({ "clangd", "pyright" })

      -- nvim 0.11+ ships default LSP maps under a "gr" prefix: grn rename,
      -- gra code action, grr references, gri implementation, grt type def.
      -- Every one of those is bound more directly below (or under <leader>c),
      -- and while they exist, pressing plain "gr" stalls for timeoutlen
      -- (1000ms) while nvim waits to see if a second key is coming. Drop them
      -- so "gr" is unambiguous and instant.
      for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
        pcall(vim.keymap.del, "n", lhs)
      end

      -- Diagnostics presentation
      vim.diagnostic.config({
        virtual_text = { spacing = 2, prefix = "●" },
        severity_sort = true,
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
          },
        },
      })

      -- The right-click menu lives in lua/menu.lua: it has to switch between
      -- code actions and file-explorer actions depending on what was clicked,
      -- so it does not belong to any one plugin's config.

      -- Show the diagnostic under the cursor after 250ms of stillness, which
      -- is the closest thing to VSCode's error hover card. Only fires when
      -- there is something to show, and never steals focus. Symbol docs are
      -- still on demand with K -- auto-showing those on every pause is noise.
      vim.api.nvim_create_autocmd("CursorHold", {
        group = vim.api.nvim_create_augroup("PalmerDiagFloat", { clear = true }),
        callback = function()
          local line = vim.api.nvim_win_get_cursor(0)[1] - 1
          if #vim.diagnostic.get(0, { lnum = line }) > 0 then
            vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
          end
        end,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("PalmerLspAttach", { clear = true }),
        callback = function(ev)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          -- The vimrc's ctags key, now backed by the language server, so it
          -- also resolves macros and statics. It opened a tab page originally;
          -- it opens a split now, because a tab page would arrive without the
          -- file explorer. One-keystroke equivalent of <leader>cv.
          map("<C-\\>", function()
            vim.cmd("vsplit")
            vim.lsp.buf.definition()
          end, "Definition to the side")

          -- Ctrl+click a symbol to jump to its definition, as in VSCode.
          -- By default <C-LeftMouse> is the old ctags jump; this moves the
          -- cursor to what you clicked first, then asks the language server.
          -- The <LeftMouse> prefix runs the click first so the cursor lands on
          -- the symbol, then the command asks the server about it.
          map("<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>",
            "Definition (ctrl+click)")

          -- Open the definition somewhere other than the current window.
          -- `vim.cmd(...)` splits first so the jump lands in the new window.
          local function def_in(split)
            return function()
              vim.cmd(split)
              vim.lsp.buf.definition()
            end
          end
          -- Splits only, no tab pages. A tab page is a whole window layout, so
          -- a definition opened in one arrives with no file explorer beside
          -- it; this config keeps a single tab page with buffers along the top.
          map("<leader>cv", def_in("vsplit"), "Definition to the side")
          map("<leader>cx", def_in("split"), "Definition below")

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", "<cmd>FzfLua lsp_references<CR>", "References")

          -- Call hierarchy as a tree, in lua/callhierarchy.lua. References
          -- answers "where is this name mentioned"; this answers "how is this
          -- reached", which needs the level above and the one above that.
          -- The module checks for callHierarchyProvider itself and says so if
          -- the server cannot answer, so no capability guard is needed here.
          -- Always follows dispatch tables. There is no cheap/expensive split
          -- to make: bridging only fires where nothing calls a node, so a
          -- function with ordinary callers costs nothing extra, and results
          -- stream, so the direct half is on screen either way.
          map("<leader>ci", function() require("callhierarchy").open("incoming", true) end,
            "Call hierarchy: who calls this")
          map("<leader>co", function() require("callhierarchy").open("outgoing", true) end,
            "Call hierarchy: what this calls")
          -- The other direction: on an ops->field(...) call site, gd only
          -- reaches the field declaration. This lists what could be assigned.
          map("<leader>cG", function() require("callhierarchy").implementations() end,
            "Possible implementations (guess ops)")
          map("gy", vim.lsp.buf.type_definition, "Type definition")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cs", "<cmd>FzfLua lsp_document_symbols<CR>", "Document symbols")
          map("<leader>cS", "<cmd>FzfLua lsp_workspace_symbols<CR>", "Workspace symbols")
          map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
          map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
          map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")

          -- clangd-specific: swap between foo.c and foo.h
          if vim.bo[ev.buf].filetype == "c" then
            map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<CR>", "Switch source/header")
          end

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end

          -- Highlight every other occurrence of the symbol under the cursor,
          -- which is the "clicking a symbol lights up its uses" behaviour from
          -- VSCode. Built into nvim; just not on by default. Debounced by
          -- 'updatetime' (250ms), so it costs one LSP request per pause.
          if client:supports_method("textDocument/documentHighlight") then
            local hl = vim.api.nvim_create_augroup("PalmerLspHl" .. ev.buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = hl,
              buffer = ev.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = hl,
              buffer = ev.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Parameter hints while typing a call. <C-s> in insert mode.
          if client:supports_method("textDocument/signatureHelp") then
            vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help,
              { buffer = ev.buf, desc = "Signature help" })
          end

          -- Inlay hints (parameter names, deduced types) shown inline. Off by
          -- default: on dense C they add a lot of visual noise, and they
          -- cost an extra request per redraw.
          if client:supports_method("textDocument/inlayHint") then
            -- <leader>cH, not <leader>ci: the latter is incoming calls, which
            -- gets reached for far more often than this does.
            map("<leader>cH", function()
              local f = { bufnr = ev.buf }
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(f), f)
            end, "Toggle inlay hints")
          end
        end,
      })
    end,
  },

  -- Completion. nvim-cmp is pure Lua; the faster Rust-based alternatives would
  -- need a working cargo, and the one on this box is from 2020.
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      { "L3MON4D3/LuaSnip", dependencies = { "saadparwaiz1/cmp_luasnip" } },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          -- Explicit confirm only: <CR> stays a newline, so completion never
          -- hijacks a return you meant literally.
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer", keyword_length = 3 },
          { name = "path" },
        }),
      })
    end,
  },

  -- The VSCode "Problems" panel.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (workspace)" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbol outline" },
    },
    opts = {},
  },
}
