-- ~/src/configs/nvim/init.lua
-- Symlinked to ~/.config/nvim. Requires nvim >= 0.11 (we ship 0.12 in
-- ~/.local/nvim/bin) -- the /bin/nvim on this box is 0.6.1 and will not work.

-- Leader must be set before lazy.nvim loads, otherwise plugins that declare
-- their own <leader> mappings bind against the old leader.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("options")

-- Bootstrap lazy.nvim ---------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  change_detection = { notify = false },
  performance = {
    rtp = {
      -- Nothing here is used; dropping them shaves startup.
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin",
      },
    },
  },
})

require("keymaps")
require("menu").setup()
