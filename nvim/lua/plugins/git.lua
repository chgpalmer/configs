-- Git. Three tools with three distinct jobs:
--   gitsigns   -- what changed on THIS line / in THIS buffer
--   diffview   -- review a whole branch or commit, VSCode-PR-style
--   fugitive   -- everything else (:Git blame, :Git log, :Git rebase -i, ...)

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false, -- toggled on demand with <leader>gb
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end

        -- Hunk navigation. ]c / [c are vim's native diff-mode motions, so
        -- this keeps that muscle memory working outside diff mode too.
        map("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
        map("n", "[c", function() gs.nav_hunk("prev") end, "Previous hunk")

        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
        map("n", "<leader>gB", function() gs.blame_line({ full = true }) end, "Blame line (full)")
      end,
    },
  },

  -- Reviewing a branch of AI-written commits is the main use case here.
  --
  --   <leader>gv   diff the working tree
  --   <leader>gm   review everything this branch adds on top of master
  --   <leader>gc   review one commit (prompts for a ref)
  --   <leader>gh   history of the current file
  --
  -- Inside diffview: <Tab>/<S-Tab> step through files, <leader>gq closes it.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      -- Three review scopes, widening: what I have not committed, what the
      -- last commit did, what this whole branch does.
      --
      -- -uno is git's --untracked-files=no. Without it DiffviewOpen lists
      -- every untracked file in the worktree alongside the real changes, which
      -- in a repo with build artefacts lying around buries the diff entirely.
      { "<leader>gv", "<cmd>DiffviewOpen -uno<CR>", desc = "Diff working tree (tracked only)" },
      -- HEAD^! is git shorthand for "this commit against its parent".
      { "<leader>gd", "<cmd>DiffviewOpen HEAD^!<CR>", desc = "Review the last commit" },
      { "<leader>gm", "<cmd>DiffviewOpen master...HEAD<CR>", desc = "Review branch vs master" },
      {
        -- Fuzzy-searchable commit list with a diff preview; Enter opens the
        -- selected commit in diffview. "<sha>^!" is git shorthand for "just
        -- this one commit", i.e. diffed against its own parent.
        "<leader>gc",
        function()
          require("fzf-lua").git_commits({
            actions = {
              ["default"] = function(selected)
                local sha = selected[1] and selected[1]:match("%x%x%x%x%x%x%x+")
                if sha then
                  vim.cmd("DiffviewOpen " .. sha .. "^!")
                end
              end,
            },
          })
        end,
        desc = "Pick a commit to review",
      },
      {
        -- Same, but only commits that touched the current file.
        "<leader>gf",
        function()
          require("fzf-lua").git_bcommits({
            actions = {
              ["default"] = function(selected)
                local sha = selected[1] and selected[1]:match("%x%x%x%x%x%x%x+")
                if sha then
                  vim.cmd("DiffviewOpen " .. sha .. "^!")
                end
              end,
            },
          })
        end,
        desc = "Pick a commit touching this file",
      },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "History of this file" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "History of this branch" },
      { "<leader>gq", "<cmd>DiffviewClose<CR>", desc = "Close diffview" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        -- Side-by-side, like a VSCode diff editor.
        default = { layout = "diff2_horizontal" },
        merge_tool = { layout = "diff3_horizontal" },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { width = 36 },
      },
    },
  },

  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Gblame" },
    keys = {
      { "<leader>gg", "<cmd>Git<CR>", desc = "Git status" },
      { "<leader>gl", "<cmd>Git log --oneline --graph --decorate -50<CR>", desc = "Git log" },
    },
  },
}
