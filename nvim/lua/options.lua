-- Editor options. Most of this is a direct port of ~/src/configs/vimrc so that
-- nvim feels like the vim you have been using since 2020.

local o = vim.opt

-- Indentation: 2 spaces, no tabs (vimrc lines 33-36)
o.shiftwidth = 2
o.softtabstop = 2
o.expandtab = true
o.autoindent = true

-- Display
o.number = true
o.ruler = true
o.cmdheight = 2 -- avoids the "press enter to continue" prompt
o.laststatus = 2
o.startofline = false -- keep column when moving between lines
o.scrolloff = 4
o.termguicolors = true
o.signcolumn = "yes" -- always on, so gitsigns/diagnostics don't shift text

-- Search (vimrc lines 46-47, 63)
o.ignorecase = true
o.smartcase = true
o.hlsearch = true

-- Misc
o.visualbell = true
o.mouse = "a"
o.wildmenu = true
o.path:append("**") -- :find searches down into subfolders
o.splitright = true
o.splitbelow = true
o.updatetime = 250 -- drives gitsigns blame + LSP hover delays
o.undofile = true -- persistent undo across sessions; vim never had this

-- Pick up edits made to a file by something else -- another editor, a script,
-- an agent -- rather than sitting on a stale copy and overwriting them.
--
-- 'autoread' is on by default but only acts when nvim happens to CHECK; it does
-- not poll. Without something triggering the check the buffer stays stale
-- indefinitely, and the first :w then writes the old contents over the new
-- ones. (vim does warn before that write, but a warning you have to read every
-- time is not a fix.)
--
-- FocusGained needs the terminal to report focus. Inside tmux that requires
-- "set -g focus-events on"; CursorHold covers the case where it does not.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("PalmerAutoReload", { clear = true }),
  callback = function()
    -- Only real file buffers, and never while a command line is open.
    if vim.bo.buftype == "" and vim.fn.mode() ~= "c" and vim.fn.expand("%") ~= "" then
      pcall(vim.cmd.checktime)
    end
  end,
})

-- Say so when it happens. A buffer changing under you silently is worse than
-- the staleness it fixes.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = "PalmerAutoReload",
  callback = function()
    vim.notify("Reloaded: file changed on disk", vim.log.levels.WARN)
  end,
})

-- Column 81 marker, magenta, exactly as the vimrc did with matchadd.
-- matchadd() is per-window, so re-apply it on every new window rather than
-- only the first one (which is all the original vimrc actually managed).
vim.api.nvim_set_hl(0, "ColorColumn", { ctermbg = "magenta", bg = "#87005f" })
vim.api.nvim_set_hl(0, "ExtraWhitespace", { ctermbg = "red", bg = "#ff0000" })

local marks = vim.api.nvim_create_augroup("PalmerMatches", { clear = true })

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew" }, {
  group = marks,
  callback = function()
    -- Guard against stacking duplicate matches when re-entering a window.
    if vim.w.palmer_matches then
      return
    end
    vim.w.palmer_matches = true
    vim.fn.matchadd("ColorColumn", "\\%81v", 100)
    vim.fn.matchadd("ExtraWhitespace", "\\s\\+$")
  end,
})

-- Don't flag trailing whitespace under the cursor while actively typing.
vim.api.nvim_create_autocmd("InsertEnter", {
  group = marks,
  callback = function()
    vim.fn.clearmatches()
    vim.fn.matchadd("ColorColumn", "\\%81v", 100)
    vim.fn.matchadd("ExtraWhitespace", "\\s\\+\\%#\\@<!$")
  end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
  group = marks,
  callback = function()
    vim.fn.clearmatches()
    vim.fn.matchadd("ColorColumn", "\\%81v", 100)
    vim.fn.matchadd("ExtraWhitespace", "\\s\\+$")
  end,
})

-- Wrap git commit messages at 72 (vimrc lines 109-111)
vim.api.nvim_create_autocmd("FileType", {
  group = marks,
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.textwidth = 72
    vim.opt_local.spell = true
  end,
})
