-- Right-click menus.
--
-- Vim menus are global, not per-buffer, so a single PopUp definition would show
-- code actions while you are right-clicking a directory in the file explorer.
-- nvim's own defaults solve this by enabling and disabling entries from a
-- MenuPopup autocmd; we do the same thing one step coarser, rebuilding the
-- whole menu for the buffer being clicked. Rebuilding is only menu definitions,
-- so it costs nothing on a human timescale.
--
-- 'mousemodel' is popup_setpos, so the cursor has already moved to whatever was
-- clicked by the time these run. Menu items can just act on the current node.
--
-- SHORTCUTS ARE PART OF THE LABEL, not a <Tab>-separated hint. Vim renders the
-- hint half of a label right-aligned only in GUI menus; the terminal popup
-- drops it silently. Writing "Hover docs (K)" is the only way the key actually
-- appears, and the point of the menu is to teach itself out of a job.
--
-- Nothing here opens a vim tab page. Tab pages are whole window layouts, so a
-- definition opened in one arrives without the file explorer beside it; this
-- config keeps everything in a single tab page with buffers along the top.

local M = {}

-- Actions for a normal file buffer: LSP navigation and edits.
local function code_menu()
  vim.cmd([[
    anoremenu PopUp.Hover\ docs\ (K)                       <Cmd>lua vim.lsp.buf.hover()<CR>
    anoremenu PopUp.Go\ to\ definition\ (gd)               <Cmd>lua vim.lsp.buf.definition()<CR>
    anoremenu PopUp.Definition\ to\ the\ side\ (<leader>cv) <Cmd>vsplit \| lua vim.lsp.buf.definition()<CR>
    anoremenu PopUp.Definition\ below\ (<leader>cx)        <Cmd>split \| lua vim.lsp.buf.definition()<CR>
    anoremenu PopUp.References\ (gr)                       <Cmd>FzfLua lsp_references<CR>
    anoremenu PopUp.Call\ hierarchy\ (<leader>ci)          <Cmd>lua require("callhierarchy").open("incoming", true)<CR>
    anoremenu PopUp.Possible\ implementations\ (<leader>cG)   <Cmd>lua require("callhierarchy").implementations()<CR>
    anoremenu PopUp.What\ this\ calls\ (<leader>co)        <Cmd>lua require("callhierarchy").open("outgoing", true)<CR>
    anoremenu PopUp.Implementations\ (gi)                  <Cmd>lua vim.lsp.buf.implementation()<CR>
    anoremenu PopUp.-1-                                    <Nop>
    anoremenu PopUp.Rename\ symbol\ (<leader>cr)           <Cmd>lua vim.lsp.buf.rename()<CR>
    anoremenu PopUp.Code\ action\ (<leader>ca)             <Cmd>lua vim.lsp.buf.code_action()<CR>
    anoremenu PopUp.Format\ (<leader>cf)                   <Cmd>lua require("conform").format({async=true,lsp_format="fallback"})<CR>
    anoremenu PopUp.-2-                                    <Nop>
    anoremenu PopUp.Line\ diagnostics\ (<leader>cd)        <Cmd>lua vim.diagnostic.open_float()<CR>
    anoremenu PopUp.All\ diagnostics\ (<leader>xx)         <Cmd>Trouble diagnostics toggle<CR>
    anoremenu PopUp.-3-                                    <Nop>
    vnoremenu PopUp.Cut\ (x)                               "+x
    vnoremenu PopUp.Copy\ (y)                              "+y
    anoremenu PopUp.Paste\ (p)                             "+gP
    vnoremenu PopUp.Paste\ (p)                             "+P
  ]])
end

-- Actions for the file explorer. Shortcuts shown are nvim-tree's own defaults,
-- so the menu teaches the real keys rather than aliases invented here.
local function tree_menu()
  vim.cmd([[
    anoremenu PopUp.Open\ (<CR>)                    <Cmd>lua require("nvim-tree.api").node.open.edit()<CR>
    anoremenu PopUp.Open\ to\ the\ side\ (C-v)      <Cmd>lua require("nvim-tree.api").node.open.vertical()<CR>
    anoremenu PopUp.Open\ below\ (C-x)              <Cmd>lua require("nvim-tree.api").node.open.horizontal()<CR>
    anoremenu PopUp.Preview\ (Tab)                  <Cmd>lua require("nvim-tree.api").node.open.preview()<CR>
    anoremenu PopUp.-1-                             <Nop>
    anoremenu PopUp.New\ file\ or\ folder\ (a)      <Cmd>lua require("nvim-tree.api").fs.create()<CR>
    anoremenu PopUp.Rename\ (r)                     <Cmd>lua require("nvim-tree.api").fs.rename()<CR>
    anoremenu PopUp.Delete\ (d)                     <Cmd>lua require("nvim-tree.api").fs.remove()<CR>
    anoremenu PopUp.-2-                             <Nop>
    anoremenu PopUp.Copy\ (c)                       <Cmd>lua require("nvim-tree.api").fs.copy.node()<CR>
    anoremenu PopUp.Cut\ (x)                        <Cmd>lua require("nvim-tree.api").fs.cut()<CR>
    anoremenu PopUp.Paste\ (p)                      <Cmd>lua require("nvim-tree.api").fs.paste()<CR>
    anoremenu PopUp.Copy\ full\ path\ (gy)          <Cmd>lua require("nvim-tree.api").fs.copy.absolute_path()<CR>
    anoremenu PopUp.-3-                             <Nop>
    anoremenu PopUp.Set\ as\ root\ (C-])            <Cmd>lua require("nvim-tree.api").tree.change_root_to_node()<CR>
    anoremenu PopUp.Up\ one\ level\ (-)             <Cmd>lua require("nvim-tree.api").tree.change_root_to_parent()<CR>
    anoremenu PopUp.File\ info\ (C-k)               <Cmd>lua require("nvim-tree.api").node.show_info_popup()<CR>
  ]])
end

-- Actions for a diffview buffer.
--
-- Diffview renders git objects into synthetic "diffview://" buffers that are
-- not files on disk, so no language server attaches and the code menu's LSP
-- entries would all fail with "not supported by any server". Offer diffview's
-- own bindings instead -- listing them, not rebinding them; diffview owns its
-- keymaps and this only teaches what is already there.
--
-- gf is the important one: it opens the real file in your editing tab page,
-- where the language server IS attached, so gd/K work again.
local function diff_menu()
  vim.cmd([[
    anoremenu PopUp.Open\ the\ real\ file\ (gf)      <Cmd>lua require("diffview.actions").goto_file_edit()<CR>
    anoremenu PopUp.Next\ file\ (Tab)                <Cmd>lua require("diffview.actions").select_next_entry()<CR>
    anoremenu PopUp.Previous\ file\ (S-Tab)          <Cmd>lua require("diffview.actions").select_prev_entry()<CR>
    anoremenu PopUp.-1-                              <Nop>
    anoremenu PopUp.Toggle\ file\ panel\ (<leader>b) <Cmd>lua require("diffview.actions").toggle_files()<CR>
    anoremenu PopUp.Focus\ file\ panel\ (<leader>e)  <Cmd>lua require("diffview.actions").focus_files()<CR>
    anoremenu PopUp.All\ diffview\ keys\ (g?)        <Cmd>lua require("diffview.actions").help({"view","diff2"})<CR>
    anoremenu PopUp.-2-                              <Nop>
    anoremenu PopUp.Close\ review\ (<leader>gq)      <Cmd>DiffviewClose<CR>
    vnoremenu PopUp.Copy\ (y)                        "+y
  ]])
end

function M.setup()
  -- nvim's own MenuPopup handler references entries by name and errors with
  -- E329 once they no longer exist, so it has to go before we take over.
  pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")

  vim.api.nvim_create_autocmd("MenuPopup", {
    group = vim.api.nvim_create_augroup("PalmerMenu", { clear = true }),
    pattern = "*",
    callback = function()
      pcall(vim.cmd, "aunmenu PopUp")
      local name = vim.api.nvim_buf_get_name(0)
      if vim.bo.filetype == "NvimTree" then
        tree_menu()
      elseif name:match("^diffview://") or vim.bo.filetype:match("^Diffview") then
        diff_menu()
      else
        code_menu()
      end
    end,
  })
end

return M
