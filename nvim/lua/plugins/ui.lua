-- Colourscheme, file explorer, fuzzy finder, statusline, keymap discovery.

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- load before everything else so there's no flash
    config = function()
      require("tokyonight").setup({ style = "night" })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- File explorer. <leader>e toggles, <leader>E reveals the current file.
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Explorer toggle" },
      { "<leader>E", "<cmd>NvimTreeFindFile<CR>", desc = "Explorer reveal file" },
    },
    -- Bare `nvim` (no file argument) opens the explorer in the sidebar and
    -- drops you straight into the file picker, so you can just start typing.
    -- `nvim some/file.c` is untouched -- it opens that file, as always.
    -- `init` runs at startup; requiring nvim-tree in the callback is what
    -- actually loads the plugin, so this costs nothing when you pass a file.
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("PalmerStartScreen", { clear = true }),
        callback = function()
          -- Only for a human at a terminal, which is the whole point of the
          -- feature. `nvim --headless` has no UI; `nvim --embed` (how GUI
          -- clients and editor plugins drive nvim over RPC) has one, but its
          -- stdout is not a tty. Opening an explorer and a fuzzy picker for a
          -- program is meaningless in both cases.
          if vim.fn.argc() ~= 0 or vim.bo.filetype ~= "" then
            return
          end
          local ui = vim.api.nvim_list_uis()[1]
          if not ui or not ui.stdout_tty then
            return
          end
          require("nvim-tree.api").tree.open()
          -- Deferred so the tree has finished drawing before the picker
          -- floats over it; otherwise the layout flickers.
          vim.schedule(function()
            pcall(function() require("fzf-lua").files() end)
          end)
        end,
      })
    end,
    opts = {
      view = { width = 36 },
      renderer = {
        group_empty = true,
        indent_markers = { enable = true },
        -- Colour the FILENAME by git status, not just the small icon beside
        -- it. The default is "none", which means a modified file looks exactly
        -- like an unmodified one unless you notice the icon -- useless when
        -- you are scanning a tree for what changed.
        highlight_git = "name",
        icons = { show = { git = true } },
      },
      -- Build trees get enormous; never walk into one.
      filters = { custom = { "^\\.git$", "^build$", "__pycache__" } },
      -- nvim-tree runs `git status` once per git top-level, so a repo with
      -- several submodules pays that cost several times over -- and over a
      -- network filesystem it dominates the first open of the tree. Skipping
      -- vendored submodule directories keeps git colours where they matter.
      -- Subsequent opens are ~16ms; only the first one per session is slow.
      --
      -- If `git status` is slow in the repo itself, `git config
      -- core.untrackedCache true` is usually the bigger win. Check it is safe
      -- on your filesystem first: `git update-index --test-untracked-cache`.
      -- $NVIM_GIT_SKIP_DIRS is a colon-separated list of Lua patterns, set in
      -- a machine-local shell file (e.g. ~/.bash_x) so site-specific paths
      -- stay out of this repo. Example: NVIM_GIT_SKIP_DIRS='/external/:/vendor/'
      git = {
        enable = true,
        timeout = 1000,
        -- Mark a directory when something inside it changed, so you can see
        -- where the work is without expanding every folder.
        show_on_dirs = true,
        show_on_open_dirs = true,
        disable_for_dirs = function(path)
          for pattern in (vim.env.NVIM_GIT_SKIP_DIRS or ""):gmatch("[^:]+") do
            if path:match(pattern) then
              return true
            end
          end
          return false
        end,
      },
      actions = { open_file = { quit_on_open = false } },
      update_focused_file = { enable = true },
    },
  },

  -- Fuzzy finder. Shells out to the native fzf and ripgrep binaries, which is
  -- what keeps it usable on very large repos.
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      -- <C-p> is what ctrlp used in the vimrc, so it stays <C-p>. It opens
      -- into the current window: the file becomes another buffer, and the
      -- bufferline along the top is the list of them. Opening a vim TAB
      -- instead would create a whole new window layout without the explorer
      -- in it, which is not what "open a file" means coming from VSCode.
      -- Ctrl-t/Ctrl-v/Ctrl-s inside the picker still override per-selection.
      { "<C-p>", "<cmd>FzfLua files<CR>", desc = "Find files" },
      { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Grep (live)" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<CR>", desc = "Grep word under cursor" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>FzfLua helptags<CR>", desc = "Help tags" },
      { "<leader>fr", "<cmd>FzfLua resume<CR>", desc = "Resume last search" },
      { "<leader>fd", "<cmd>FzfLua diagnostics_workspace<CR>", desc = "Diagnostics" },
      -- Command palette, i.e. VSCode's ctrl+shift+p: fuzzy-search every ex
      -- command, including those added by plugins, and run it.
      -- Not bound to <C-S-p> because most terminals cannot distinguish
      -- ctrl+shift+p from ctrl+p.
      { "<leader>P", "<cmd>FzfLua commands<CR>", desc = "Command palette" },
      -- Fuzzy-search every keymap, showing what each one is bound to. The
      -- fastest way to answer "is there already a key for this?".
      { "<leader>fk", "<cmd>FzfLua keymaps<CR>", desc = "Search keymaps" },
      { "<leader>fp", "<cmd>FzfLua builtin<CR>", desc = "All fzf-lua pickers" },
    },
    opts = {
      -- fzf-lua resolves "fzf" from PATH and requires >= 0.36. If it aborts
      -- saying the version is too low, an old copy is winning the PATH race:
      -- fix the PATH, not this file.

      -- The picker's prompt is a text field, not a vim buffer, so readline
      -- keys are the right idiom there -- same as bash. fzf-lua already binds
      -- ctrl-a/ctrl-e/ctrl-u; ctrl-k was missing and fell through to fzf's own
      -- default, which moves up the list instead of killing to end of line.
      -- NOTE: this table REPLACES fzf-lua's defaults rather than merging into
      -- them, so the stock bindings have to be restated or they are lost.
      keymap = {
        fzf = {
          -- readline editing, as in bash
          ["ctrl-a"] = "beginning-of-line",
          ["ctrl-e"] = "end-of-line",
          ["ctrl-k"] = "kill-line", -- was missing; fzf's default moved up the list
          ["ctrl-u"] = "unix-line-discard",
          ["ctrl-w"] = "backward-kill-word",
          ["ctrl-d"] = "delete-char",
          -- stock fzf-lua bindings, restated because of the replace above
          ["ctrl-b"] = "half-page-up",
          ["ctrl-f"] = "half-page-down",
          ["ctrl-z"] = "abort",
          ["alt-a"] = "toggle-all",
          ["alt-g"] = "first",
          ["alt-G"] = "last",
          ["f3"] = "toggle-preview-wrap",
          ["f4"] = "toggle-preview",
          ["shift-down"] = "preview-page-down",
          ["shift-up"] = "preview-page-up",
          ["alt-shift-down"] = "preview-down",
          ["alt-shift-up"] = "preview-up",
        },
      },
      files = {
        -- fd already honours .gitignore AND .git/info/exclude, so per-repo
        -- noise (untracked build artefacts and the like) belongs in that
        -- repo's .git/info/exclude rather than hardcoded here -- it then
        -- cleans up `git status` at the same time.
        -- build/ is listed explicitly because it is often partly tracked,
        -- which means .gitignore misses it.
        fd_opts = "--color=never --type f --hidden --follow"
          .. " --exclude .git --exclude build",
      },
      grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case "
          .. "--max-columns=4096 --glob=!build/ --glob=!.git/",
      },
    },
  },

  -- Breadcrumbs in the winbar: where the cursor is, as
  -- "folder > file > function > if > loop". Useful in long source files
  -- where the function header scrolled off the top hours ago.
  --
  -- Every component is CLICKABLE and opens a dropdown -- click a folder to
  -- switch file, click a function to jump to a sibling. That is why the path
  -- half is worth keeping even though lualine also shows the filename.
  -- To show symbols only, set: opts = { bar = { sources = ... } } -- see
  -- :help dropbar-configuration.
  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      -- Keyboard equivalent of clicking a breadcrumb.
      { "<leader>cb", function() require("dropbar.api").pick() end, desc = "Pick breadcrumb" },
    },
  },

  -- Render markdown in the buffer -- headings, tables, code blocks, links --
  -- rather than showing the raw syntax. Useful for READMEs and for the
  -- markdown that agents tend to leave lying around.
  --
  -- Deliberately NOT lazy-loaded: the plugin does its own lazy loading, and
  -- wrapping it in another layer is what its documentation warns against. It
  -- has to load after the colourscheme to pick up highlight groups, which the
  -- tokyonight spec above guarantees with priority 1000.
  --
  -- No hard dependencies. It needs the markdown and markdown_inline treesitter
  -- parsers, which nvim ships with, and picks up nvim-web-devicons for icons
  -- if present -- it is, as a dependency of the explorer and the picker.
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    keys = {
      { "<leader>cM", "<cmd>Markview toggle<CR>", desc = "Toggle markdown rendering" },
    },
  },

  -- LSP progress in the corner, so "the server is still indexing" is
  -- distinguishable from "the server is broken".
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      notification = { window = { winblend = 0 } },
    },
  },

  -- The tab bar along the top. It lists BUFFERS, not vim tab pages.
  --
  -- This is the bit that reconciles vim's model with VSCode's. In VSCode a
  -- window has one sidebar and many editor tabs; in vim a tab page is a whole
  -- window layout that would need its own copy of the explorer. VSCode's tabs
  -- are really vim's buffers, so showing buffers here gives the expected shape
  -- with one vim tab: explorer pinned on the left, open files across the top.
  --
  -- The `offsets` entry is what indents the bar past the explorer instead of
  -- drawing over it.
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    keys = {
      -- Defined here rather than in keymaps.lua so they follow the order you
      -- see in the bar, which is not the same as :bnext's buffer-number order.
      { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
      -- Same , / . sense as the tmux window bindings, one level down: tmux
      -- moves between windows, this moves between files. Under <leader>
      -- because bare "." is vim's repeat-last-change, which is not worth
      -- losing, and Alt belongs to tmux.
      { "<leader>,", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
      { "<leader>.", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
      { "<leader>bb", "<cmd>BufferLinePick<CR>", desc = "Jump to buffer by letter" },
      { "<leader>bc", "<cmd>BufferLinePickClose<CR>", desc = "Close buffer by letter" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Close other buffers" },
    },
    opts = {
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp", -- error/warning counts on each name
        always_show_bufferline = true,
        show_close_icon = false, -- no global close; per-buffer ones are enough
        offsets = {
          {
            filetype = "NvimTree",
            text = "Explorer",
            highlight = "Directory",
            separator = true,
          },
        },
      },
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "tokyonight",
        section_separators = "",
        component_separators = "|",
        globalstatus = false, -- laststatus=2 in options.lua, one bar per window
      },
      sections = {
        lualine_c = { { "filename", path = 1 } }, -- path relative to cwd
      },
    },
  },

  -- Press <leader> and wait: it shows you every binding. This is the thing
  -- that means you never have to memorise the new half of the config.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
      -- The cheat sheet. <leader>? and <leader>h both land here, because
      -- those are the two things a hand reaches for.
      { "<leader>?", function() require("which-key").show({ global = true }) end, desc = "Cheat sheet (all keymaps)" },
      { "<leader>h", function() require("which-key").show({ global = true }) end, desc = "Cheat sheet (all keymaps)" },
    },
    opts = {
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code" },
        { "<leader>b", group = "buffer" },
        { "<leader>x", group = "diagnostics" },
      },
    },
  },
}
