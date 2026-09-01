-- Syntax, formatting, commenting.

return {
  -- Treesitter gives real syntax-aware highlighting and indentation. nvim 0.12
  -- ships parsers for c/lua/markdown/vim already; this is mainly here for
  -- python, bash and the rest.
  -- NOTE: this MUST be the "main" branch. The old "master" branch is frozen
  -- and its query predicates still assume the pre-0.11 treesitter API where
  -- `match[capture_id]` was a single node; on nvim 0.11+ it is a list, so
  -- `node:range()` blows up. That surfaces as a stack traceback the first time
  -- you press K over a symbol, because LSP hover docs are rendered as markdown
  -- and markdown injections run the broken predicate.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup()

      -- nvim 0.12 already bundles c, lua, markdown, markdown_inline, query,
      -- vim and vimdoc, so only ask for the ones genuinely missing.
      local want = { "python", "bash", "yaml", "json", "gitcommit", "diff" }
      local ok, cfg = pcall(require, "nvim-treesitter.config")
      if ok then
        local have = cfg.get_installed("parsers") or {}
        local missing = vim.tbl_filter(function(p)
          return not vim.tbl_contains(have, p)
        end, want)
        if #missing > 0 then
          require("nvim-treesitter").install(missing)
        end
      end

      -- The main branch does not enable highlighting for you; starting it per
      -- filetype is the documented replacement for the old highlight module.
      -- pcall because a filetype with no parser installed is normal, not an
      -- error worth interrupting the user for.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("PalmerTreesitter", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if lang then
            pcall(vim.treesitter.start, ev.buf, lang)
          end
        end,
      })
    end,
  },

  -- Formatting. The repo already has a .clang-format, and black/isort are
  -- already in ~/.local/bin, so this just wires up what's there.
  --
  -- Deliberately NOT format-on-save: in a shared codebase that produces
  -- noisy diffs in files you only meant to read. <leader>cf formats on demand.
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer/selection",
      },
    },
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        lua = { "stylua" },
        -- Only reformat Python where the project has actually opted in. A repo
        -- that lints with pylint/mypy and carries no black or isort config
        -- gets an enormous spurious diff the first time black runs over a
        -- file, which is exactly the kind of noise you do not want to send
        -- for review. Formatting is manual (<leader>cf), but "manual" is not
        -- the same as "intended".
        python = function(bufnr)
          local markers = { "pyproject.toml", ".isort.cfg", ".black", "setup.cfg", "tox.ini" }
          if vim.fs.root(bufnr, markers) then
            return { "isort", "black" }
          end
          return {}
        end,
      },
      -- No format_on_save key: see the note above.
    },
  },

  -- gcc to comment a line, gc in visual mode. Tiny, no config.
  { "echasnovski/mini.comment", event = "VeryLazy", opts = {} },

  -- Auto-close brackets/quotes, and integrate with cmp so confirming a
  -- function completion adds the parens.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
}
