-- Core keymaps. Plugin-specific ones live next to their plugin spec in
-- lua/plugins/ so that lazy.nvim can use them as lazy-load triggers.
--
-- <C-\> is the vimrc's ctags key. This is the fallback for buffers with no
-- language server; lua/plugins/lsp.lua overrides it with the LSP version on
-- LspAttach. It opens a split rather than a tab page, because a tab page is a
-- whole window layout and would arrive without the file explorer.

local map = vim.keymap.set

map("n", "<C-\\>", "<cmd>vsplit<CR><cmd>exec 'tag ' .. expand('<cword>')<CR>",
  { desc = "Tag definition to the side" })

-- <F2> to hard-wrap at 72, as in the vimrc
map("n", "<F2>", "<cmd>set textwidth=72<CR>", { desc = "textwidth=72" })
map("i", "<F2>", "<Esc><cmd>set textwidth=72<CR>a", { desc = "textwidth=72" })

-- Reload every buffer that changed on disk. This happens automatically on
-- focus and after a pause, so it is only for when you know something just
-- rewrote a file and want it now. Modified buffers are never touched.
map("n", "<leader>r", "<cmd>checktime<CR>", { desc = "Reload changed files" })

-- Clear search highlight. hlsearch is on, so this gets used a lot.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Window navigation without the <C-w> prefix
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Keep the cursor centred when paging through search results
map("n", "n", "nzzzv", { desc = "Next match (centred)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centred)" })

-- Move visual selection up/down and reindent
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Paste over a selection without clobbering the unnamed register
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Buffers. [b / ]b and the <leader>b pickers live in the bufferline spec, so
-- that they cycle in the order shown in the bar rather than by buffer number.
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Quickfix, which trouble.nvim also feeds
map("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })
