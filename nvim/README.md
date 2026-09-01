# nvim config

Hand-rolled on lazy.nvim, ~24 plugins. Aimed at C and Python with an
IDE-ish feel, while still starting in about the same time as plain vim.

Symlink it into place:

```sh
ln -sfn ~/src/configs/nvim ~/.config/nvim
```

Leader is `<Space>`. **Press `<Space>` and wait** — which-key lists what is
available. `<leader>?` is the full cheat sheet and `<leader>fk` searches every
keymap. Those three are the intended way to find things; the tables below are
backup.

## Requirements

- **nvim >= 0.11.** Uses `vim.lsp.config`/`vim.lsp.enable` and the 0.11+
  diagnostic API. Distro packages are frequently years old — check `nvim -v`
  before assuming a bug.
- `git`, `fzf` **>= 0.36**, `ripgrep`, `fd`
- `clangd` and `pyright-langserver` on PATH for C and Python
- Optional: `clang-format`, `black`, `isort`, `stylua` for `<leader>cf`
- A **Nerd Font** selected in your terminal, or the icons render as blanks.
  In a terminal → ssh → tmux chain, the font is set by the terminal emulator
  at the near end; nothing on the remote host affects it.

Also make sure the shell has a UTF-8 locale (`LANG=...UTF-8`). Under `LANG=C`,
tmux miscomputes the display width of wide glyphs and alignment breaks.

## Machine-specific settings

Anything site-specific stays **out of this repo** and goes in a machine-local
shell file:

| Variable | Effect |
|---|---|
| `NVIM_GIT_SKIP_DIRS` | Colon-separated Lua patterns. Directories matching are skipped when the file explorer computes git status. Useful for vendored submodules. Example: `/external/:/vendor/` |

Per-repository noise (untracked build output) belongs in that repo's
`.git/info/exclude` — `fd` honours it, so it cleans up both the file picker and
`git status`, and it is not committed.

## Carried over from the vimrc

`<C-p>` is fuzzy file open, as ctrlp had it. `<C-\>` opens a definition to the
side — the old ctags binding, now backed by the language server, so it also
resolves macros and statics. It opens a split rather than a tab page, since a
tab page would arrive without the explorer. `<F2>` sets
textwidth=72. 2-space indent, magenta column 81, red trailing whitespace,
smartcase, hlsearch and mouse all behave as before.

## Navigation

| Key | Does |
|---|---|
| `<C-p>` / `<leader>ff` | find file |
| `[b` / `]b` | previous / next file in the tab bar |
| `<leader>,` / `<leader>.` | same, matching the tmux window bindings |
| `<C-^>` | flick to the **previous file** (vim built-in) |
| `<leader>bb` / `<leader>bc` | jump to / close a file by letter |
| `<leader>fg` | live grep (ripgrep, honours .gitignore) |
| `<leader>fw` | grep word under cursor |
| `<leader>fb` | switch buffer |
| `<leader>fr` | resume last search |
| `<leader>e` | file explorer toggle |
| `<leader>E` | reveal current file in explorer |
| `<C-h/j/k/l>` | move between windows |

Bare `nvim` opens the explorer in a sidebar and drops you into the file picker,
so you can just start typing. `nvim path/to/file` behaves normally. In the
explorer, **double-click** expands/collapses a folder or opens a file.

Inside the picker, `Ctrl-t` / `Ctrl-v` / `Ctrl-s` override per selection.

## Tabs, buffers, and why the layout is the way it is

The bar along the top lists **buffers**, not vim tab pages, and everything
lives in a single vim tab. That is deliberate.

VSCode has one window holding one sidebar and many editor tabs. vim has many
tab pages, each a complete window layout — so opening a file in a new vim tab
gives you a fresh layout with no explorer in it. The resolution is that
**VSCode's tabs are vim's buffers**; a vim tab page is closer to a whole VSCode
window. So: one tab, explorer pinned left, buffers across the top.

`gt` / `gT` still switch vim tabs if you ever make one (`:tabnew`), but for
normal work you want `[b` / `]b`, or just click.

**Right-click is context-dependent.** In a code buffer it offers LSP actions;
in the explorer it offers open/open-in-tab/open-to-the-side, rename, delete,
new file, copy/cut/paste and set-as-root. Both list the keyboard shortcut for
every entry. See `lua/menu.lua`.

The **winbar** shows where you are: `dir › file › function › loop`. Every
component is clickable and opens a dropdown; `<leader>cb` is the keyboard
equivalent.

## Finding things that aren't files

| Key | Does |
|---|---|
| `<leader>?` / `<leader>h` | **cheat sheet** — every keymap, grouped |
| `<leader>P` | **command palette** — VSCode's ctrl+shift+p |
| `<leader>fk` | search all keymaps |
| `<leader>fp` | list every fzf-lua picker |

`<leader>P` rather than `<C-S-p>` because most terminals cannot tell
ctrl+shift+p apart from ctrl+p.

## Code

**Right-click** in a code buffer opens a menu of these with the hotkey beside
each entry. It is meant as a crutch you stop needing.

| Key | Does |
|---|---|
| `K` | hover docs — signature, type, macro expansion |
| `gd` / `gD` | definition / declaration |
| ctrl+click | definition |
| `<C-\>` | definition **to the side** (one keystroke) |
| `<leader>cv` / `<leader>cx` | definition to the side / below |
| `<C-o>` / `<C-i>` | back / forward through jumps, across files |
| `gr` | references (fuzzy list) |
| `gi` | implementations |
| `<C-s>` (insert) | signature help while typing a call |
| `<leader>ca` / `<leader>cr` | code action / rename symbol |
| `<leader>cf` | format — never automatic on save |
| `<leader>ch` | switch .c ↔ .h |
| `<leader>ci` | **call hierarchy** — who calls this, and who calls them |
| `<leader>co` | the same downward — what this calls |
| `<leader>cg` | call hierarchy, **guessing across ops-struct dispatch** |
| `<leader>cG` | possible implementations of the `ops` field under the cursor |
| `<leader>cH` | toggle inlay hints (off by default: noisy) |
| `<leader>cs` / `<leader>cS` | document / workspace symbols |
| `[d` / `]d` | previous / next diagnostic |
| `<leader>xx` | diagnostics panel (VSCode "Problems") |

Pausing on a symbol highlights its other occurrences; pausing on a diagnostic
pops it up. Both are driven by `updatetime` (250ms).

**Call hierarchy vs references.** `gr` finds every mention of a name;
`<leader>ci` finds the functions that actually *call* it, then who calls those,
four levels up, shown as an indented tree in the usual fzf picker with a
preview of each call site. See `lua/callhierarchy.lua`.

It is a static analysis, so anything dispatched through a function pointer
registered at runtime is invisible — a branch ends at whatever installs the
callback.

`<leader>cg` and `<leader>cG` guess across that gap for the C dispatch-table
pattern, by matching the struct field name: find the field a function is
assigned to, find calls through that field, and resume the real hierarchy from
there. **These are guesses** — a field name shared by two unrelated structs
produces false edges — so guessed rows are marked `[guess: via ->field]`, and
`AMBIGUOUS` is added when more than one struct declares that field name. The
plain `<leader>ci` never guesses.

Completion: `<Tab>` cycles, **`<C-y>` confirms**. `<CR>` is always a real
newline — completion never steals it.

## Git — reviewing a branch of commits

| Key | Does |
|---|---|
| `<leader>gm` | **review everything this branch adds on top of master** |
| `<leader>gc` | pick a commit to review (fuzzy list with preview) |
| `<leader>gf` | pick a commit that touched this file |
| `<leader>gd` | **review the last commit** (HEAD^!) |
| `<leader>gv` | diff the working tree, tracked files only |
| `<leader>gh` / `<leader>gH` | history of this file / this branch |
| `<leader>gq` | close the diff view |
| `<leader>gg` / `<leader>gl` | git status / log (fugitive) |

`<leader>gm` is the closest thing to a pull-request review: a panel listing
every changed file, and side-by-side diffs with full surrounding context.
`<Tab>` / `<S-Tab>` step through files, `g?` shows every binding.

Diffview renders git objects into synthetic `diffview://` buffers, which are
not files on disk, so **no language server attaches and `K` / `gd` / `gr` do
not work there**. Press **`gf`** to open the real file in your editing tab
page, where they do. Diffview opens in its own tab page, so `gt` / `gT` flip
between reviewing and editing.

Per-line, in any buffer:

| Key | Does |
|---|---|
| `]c` / `[c` | next / previous hunk |
| `<leader>gp` / `<leader>gs` / `<leader>gr` | preview / stage / reset hunk |
| `<leader>gb` | toggle inline blame |

## C indexing

clangd reads `compile_commands.json`, found via a `.clangd` file at the project
root:

```yaml
CompileFlags:
  CompilationDatabase: build/some-target
  Remove: [-mabi=*, -march=*]   # flags clangd's parser rejects
```

If clangd reports `'foo/bar.h' file not found` followed by
`too many errors emitted`, the file is almost certainly **absent from the
database** — wrong build directory, or one built before the file existed. Check
with:

```sh
grep -c my_file.c build/some-target/compile_commands.json
```

Zero means the database is wrong or stale, not that clangd is broken.

## Maintenance

- `:Lazy` — plugin manager UI; `U` updates. `lazy-lock.json` pins versions, so
  an update that breaks something is revertible.
- `:checkhealth` — diagnose anything broken
- `:LspInfo` / `:LspLog` — is a server attached, and why not

### Two version pins that will bite if forgotten

**nvim-treesitter must stay on the `main` branch.** `master` is frozen and its
query predicates assume the pre-0.11 API, where `match[capture_id]` was a
single node rather than a list. On nvim 0.11+ that throws
`attempt to call method 'range' (a nil value)` the first time you press `K` —
hover docs render as markdown, and markdown injections run the broken
predicate.

**`tree-sitter-cli` may need pinning.** The `main` branch builds parsers with
the tree-sitter CLI rather than a bare C compiler. Recent releases are built
against GLIBC 2.39; on an older distro they fail with
`version 'GLIBC_2.39' not found`. 0.24.7 is the last version that works on
GLIBC 2.35. Only needed when installing parsers, never at startup.

To add a parser: `:lua require("nvim-treesitter").install({"rust"})`

### If startup feels slow

Neovim stats thousands of files across its runtime and plugin directories at
startup. On a network-mounted home directory that costs real time — measured on
one such setup, 330ms from NFS versus 117ms with the runtime and plugin data on
local disk. Keep `~/.config/nvim` wherever your dotfiles live, and point
`XDG_DATA_HOME` / `XDG_STATE_HOME` / `XDG_CACHE_HOME` at local disk via a small
wrapper script. Set those in a wrapper rather than exporting them from your
shell rc — plenty of other programs read them.

Profile with `nvim --startuptime /tmp/s.txt`, then sort by the second column.
