"2345678901234567890123456789012345678901234567890123456789012345678901234567890
" ##############################################################################
" # .vimrc
" ##############################################################################


" # Allow saving of files as sudo when I forgot to start vim using sudo
"command W silent execute 'write !sudo tee ' . shellescape(@%, 1) . ' >/dev/null'

" # Colorscheme
" ################################################
"colorscheme default
colorscheme desert
"highlight ColorColumn ctermbg=123 guibg=#2c2d27
"set colorcolumn=80
"highlight ColorColumn ctermbg=0 guibg=#2c2d27

" # Line numbering
" ################################################
set number

" # Filetype (smart options for files)
" ################################################
filetype on             " Detect filetype and add syntax highlighting, options
syntax on 		" source code highlighting
filetype plugin on      " Load filetype specific plugin (does clever things)
filetype indent on      " Load filetype specific indenting (e.g after {)

" # Indentation / tabs
" ################################################
" Indentation settings for using 4 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent

" # Command Window
" ################################################
set cmdheight=2         " avoids <enter to continue> because of small window
set laststatus=2        " always display status line

" # Search
" ################################################
" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

" # (Fuzzy) File searching and completion
" ################################################
" Provides tab-completion for all file-related tasks
set path+=**            " Search down into subfolders
set wildmenu		" If there are multiple matches, put them in a menu

" # Ctags
" ################################################
" Open ctag in tab/vertical split
map <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
map <leader><C-\> :vsp <CR>:exec("tag ".expand("<cword>"))<CR>

" # Other stuff
" ################################################
set hlsearch		" search highlighting
set visualbell          " visual cue when doing things wrong
" set mouse=a             " enable mouse
set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set nocompatible	" Use Vim defaults (much better!)
set nostartofline       " tries to go to the same point when moving between
                        "  lines, breaking compatibility with vi but who cares
set backspace=indent,eol,start  " backspace through newlines in insert mode etc...

" # Trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" # Remember last position when re-opening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" ################################################
" # Plugins
" ################################################

" # Pathogen
" ################################################
"execute pathogen#infect()

" # NERDTree
" ################################################
"nmap <ESC>t :NERDTreeToggle<CR>

" # /.vimrc

