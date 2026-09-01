#!/usr/bin/env bash
# configs bootstrap. Symlinks the core dotfiles (bash/vim/tmux/screen) into place
# and sets up tmux's plugin manager. Run from anywhere -- works two ways:
#
#   # From a fresh machine (clones the repo, then links):
#   curl -fsSL https://raw.githubusercontent.com/chgpalmer/configs/work/install.sh | bash
#
#   # From an existing checkout:
#   ./install.sh
#
# In bootstrap mode the repo is cloned to ~/src/configs. Override:
#   CONFIGS_DIR=~/dotfiles bash <(curl -fsSL ...)
#
# Idempotent: re-running relinks anything stale and leaves correct links alone.
# Existing real files are backed up to <path>.backup-<timestamp> before linking.
set -eu

REPO_URL="${REPO_URL:-https://github.com/chgpalmer/configs}"
BRANCH="${BRANCH:-work}"
TS="$(date +%Y%m%d-%H%M%S)"

echo "== configs bootstrap =="

# 0. Bootstrap packages: enough to clone and to actually use the linked configs.
#    Skips silently on non-apt systems and only installs what is missing.
if command -v apt-get >/dev/null 2>&1; then
  missing=()
  for p in git vim tmux; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "-- installing packages: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
  else
    echo "-- packages present (git vim tmux)"
  fi
fi

# 1. Locate the checkout. If this script lives inside a checkout (local run) use
#    that; otherwise (piped from curl) clone the repo to CONFIGS_DIR.
is_checkout() { [ -f "$1/bashrc" ] && [ -f "$1/tmux.conf" ]; }

self="${BASH_SOURCE[0]:-}"
src_dir=""
if [ -n "$self" ] && [ -f "$self" ]; then
  src_dir="$(cd "$(dirname "$self")" && pwd)"
fi

if [ -n "$src_dir" ] && is_checkout "$src_dir"; then
  CONFIGS_DIR="$src_dir"
  echo "-- using checkout at $CONFIGS_DIR"
else
  CONFIGS_DIR="${CONFIGS_DIR:-$HOME/src/configs}"
  if is_checkout "$CONFIGS_DIR"; then
    echo "-- using existing checkout at $CONFIGS_DIR"
  elif [ -e "$CONFIGS_DIR" ]; then
    echo "ERROR: $CONFIGS_DIR exists but is not a configs checkout." >&2
    echo "       Move it aside or set CONFIGS_DIR to a different path." >&2
    exit 1
  else
    echo "-- cloning $REPO_URL ($BRANCH) -> $CONFIGS_DIR"
    git clone --branch "$BRANCH" "$REPO_URL" "$CONFIGS_DIR"
  fi
fi

# 2. Symlink the core dotfiles. Note tmux lives at ~/.config/tmux/tmux.conf --
#    that path is baked into the reload binding and TPM loader in tmux.conf.
link() {
  local src="$CONFIGS_DIR/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      echo "   ok    $dst"
      return
    fi
    ln -sfn "$src" "$dst"
    echo "   relink $dst"
    return
  fi
  if [ -e "$dst" ]; then
    mv "$dst" "$dst.backup-$TS"
    echo "   backup $dst -> $dst.backup-$TS"
  fi
  ln -s "$src" "$dst"
  echo "   link  $dst"
}

echo "-- linking dotfiles"
link bashrc       "$HOME/.bashrc"
link bash_profile "$HOME/.bash_profile"
link profile      "$HOME/.profile"
link vimrc        "$HOME/.vimrc"
link screenrc     "$HOME/.screenrc"
link tmux.conf    "$HOME/.config/tmux/tmux.conf"
# nvim/ is a directory; link() handles it the same way. Deliberately not added
# to the apt list above: distro neovim is frequently 0.6.x and this config
# needs >= 0.11, so it wants an upstream build. nvim/README.md lists what else
# it expects on PATH (fzf >= 0.36, ripgrep, fd, clangd, pyright).
link nvim         "$HOME/.config/nvim"

# emacs/ has its own installer, which also does the symlink -- distro Emacs is
# 27.1 on Ubuntu 22.04 and that predates eglot, tree-sitter, use-package and
# native compilation being in core. Unlike the nvim runtime above, this one is
# scripted: it needs no root and installs to /scratch. Run with EMACS_SKIP=1 to
# link the other dotfiles without spending ~200MB of download on it.
if [ -z "${EMACS_SKIP:-}" ] && [ -x "$CONFIGS_DIR/emacs/install-emacs.sh" ]; then
  echo "-- emacs (set EMACS_SKIP=1 to skip)"
  "$CONFIGS_DIR/emacs/install-emacs.sh" || echo "   (emacs install failed; continuing)"
else
  echo "-- emacs skipped"
fi

# 3. tmux plugin manager + plugins (resurrect/continuum, declared in tmux.conf).
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "-- cloning tpm -> $TPM_DIR"
  git clone --quiet https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "-- tpm present"
fi
echo "-- installing tmux plugins"
if ! "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1; then
  echo "   (plugin install skipped -- run <prefix> + I inside tmux to finish)"
fi

cat <<EOF

== done ==
  Restart your shell (or: source ~/.bashrc) to pick up bash config.
  Start tmux; plugins load automatically.

  Note: bash_profile/profile reference cargo, npm and xrandr. On a box without
  rust/node/X those print harmless errors at login -- not touched by this script.
EOF
