#2345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
# .bashrc
################################################################################
# Sources:
# https://www.ukuug.org/events/linux2003/papers/bash_tips/

export EDITOR=vi

# this allows passing arbitrary commands to be executed, useful for magic sshing!
if ! [ -z $_BASHRC_CUSTOM_CMD ]; then
  eval $_BASHRC_CUSTOM_CMD
fi

# Colouring command line things
##################################################
#alias rrep='grep --color=auto --exclude-dir=".git;.svn;.hg;" --exclude-from="TAGS"'
#alias grepc='grep --color=always --exclude-dir=".git;.svn;.hg;" --exclude-from="TAGS"'
alias sudo='sudo ' # makes sudo xyz also alias
alias gr='grep -r --color=always --exclude="TAGS" --exclude="tags" --exclude-dir="build"'
alias grep='grep --color=auto --exclude="TAGS" --exclude="tags"'
alias grepc='grep --color=always --exclude="TAGS" --exclude="tags"'
alias egrep='egrep --color=auto'
alias egrepc='egrep --color=always'
alias less='less -R'              # print ANSI colours when piped from grepc
alias la='ls -lah --color=tty'
alias ll='ls -lhrt --color=tty'
alias ls='ls --color=tty'
alias tree='tree -C'
alias tree1='tree -C -L 1'
alias tree2='tree -C -L 2'
alias tree3='tree -C -L 3'
alias src='cd ~/src; ll'
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' # colour gcc v4.9+
alias g++="g++ -fdiagnostics-color=always
alias gcc="g++ -fdiagnostics-color=always

alias vi='vim'
#alias vim='if $(hash gvim 2>/dev/null); then gvim; else vim; fi;'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
#alias ssh='ssh -X'
alias ssh="/home/$USER/bin/sshwait" 
alias vimt='vim -c "NERDTree" $1'
if $(hash colordiff 2>/dev/null); then alias cdiff='colordiff'; fi

# GIT
######
alias gitlog="git log --all --graph --decorate"
alias gitqrefresh="git commit -a --fixup HEAD; git rebase -i --autosquash HEAD~2"
alias suc="su -c '/bin/bash --rcfile ~$USER/.bashrc -i'" 
alias dd="dd status=progress"
alias dateF="date +\"%Y-%m-%d_%H-%M\""
alias rebashrc="unalias -a; source /home/$USER/.bashrc"
alias wifi-tui="nmtui"
alias wifi-gui="nm-connection-editor"
alias wifi-applet="nm-applet"
alias psef="ps -ef | head -n1; ps -ef | tail -n+2"
alias gby="gatsby"
# Do once things
##################################################
shopt -s checkwinsize # stops the prompt occasionally eating itself
shopt -s histappend # append session HIST to HISTFILE, possibly not needed with 'history -a' in PROMPT_COMMAND, but it won't hurt
HISTSIZE=20000 # history lines available in session
HISTFILESIZE=100000 # total history lines stored
HISTCONTROL=ignoredups # dont store line if same as prev (session) line

export PATH=$PATH:/home/$USER/.local/bin

# Do environment specific stuff if file exits
##################################################
if [ -f /home/$USER/.bash_x ]; then
  source /home/$USER/.bash_x
fi

# Terminal title
##################################################
#PROMPT_COMMAND='echo -ne "\033]0;$(hostname)\007"' # terminal title = hostname
#PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'

# Prompt!
##################################################
# Colors
#Regular text color
BLACK='\[\e[0;30m\]'
#Bold text color
BBLACK='\[\e[1;30m\]'
#background color
BGBLACK='\[\e[40m\]'
RED='\[\e[0;31m\]'
BRED='\[\e[1;31m\]'
BGRED='\[\e[41m\]'
GREEN='\[\e[0;32m\]'
BGREEN='\[\e[1;32m\]'
BGGREEN='\[\e[1;32m\]'
YELLOW='\[\e[0;33m\]'
BYELLOW='\[\e[1;33m\]'
BGYELLOW='\[\e[1;33m\]'
BLUE='\[\e[0;34m\]'
BBLUE='\[\e[1;34m\]'
BGBLUE='\[\e[1;34m\]'
MAGENTA='\[\e[0;35m\]'
BMAGENTA='\[\e[1;35m\]'
BGMAGENTA='\[\e[1;35m\]'
CYAN='\[\e[0;36m\]'
BCYAN='\[\e[1;36m\]'
BGCYAN='\[\e[1;36m\]'
WHITE='\[\e[0;37m\]'
BWHITE='\[\e[1;37m\]'
BGWHITE='\[\e[1;37m\]'
BROWN='\033[38;5;130m'

# PROMPT_COMMAND is run every line
PROMPT_COMMAND=prompt_command


function prompt_command
{
  local EXIT="$?"
  local DF='\[\e[0m\]'

  base_prompt
  hg_prompt
  git_prompt
  smile_prompt $EXIT
  prompt_symbol
  history -a # append previous line to disk
  PS1=$PS1${DF}" "

  # my ssh script sets $_SSH_FROM_GUI by using a rcfile wrapper, so this is implemented in three places...
  if ! [ -z $DESKTOP_SESSION ] || ! [ -z $_SSH_FROM_GUI ]; then
    echo -ne "\033]0;$(hostname)\007" # terminal title = hostname
  fi

}

function prompt_symbol
{
if [ $UID -eq 0 ]; then
  #root
  PS1+=#
else
  #normal user
  PS1+=$
fi
}

function base_prompt
{
if [ $UID -eq 0 ]; then
  #root user color
  local UC="${RED}"
  #hostname
  local HC="${BRED}"
else
  #normal user color
  local UC="${BMAGENTA}"
  #hostname
  local HC="${BMAGENTA}"
fi
#regular color
local RC="${BWHITE}"
#default color
local DF='\[\e[0m\]'
#PS1="[${UC}\u${RC}${BBLACK}@${HC}\h ${RC}\W${DF}]${DF}"
PS1="[${HC}\h${BBLACK}:${RC}\W${DF}]"
}

function smile_prompt
{
local DF='\[\e[0m\]'
if [[ $1 != 0 ]]; then
    PS1+=${RED}":("${DF}
#else
#    PS1+=":)"
fi
}

function hg_prompt
{
#hg_exist=$(ls -a | egrep "^\.hg$" 2> /dev/null)
local hg_exist=$(/home/$USER/.local/bin/find_hg 2>/dev/null) # 2>... as uklogin shouts about about stale NFS handles
if [ -n "$hg_exist" ]; then
local hg_root=$hg_exist"/.hg/"
local DF='\[\e[0m\]'
#local branch=$(hg branch 2> /dev/null)
#local bookmark=$(hg bookmarks 2> /dev/null | grep "^ \*" | sed 's/^ \* //g' | sed 's/ *[0-9]*:[0-9a-z]*$//g')
#bewlow works but annoyingly slow!
#local branchbookmarkpatch=$(hg prompt "1{branch} 2{bookmark} 3{patch}" 2> /dev/null)
#local arr=($branchbookmarkpatch)
#local branch=${arr[0]}; branch=${branch#?}
#local bookmark=${arr[1]}; bookmark=${bookmark#?}
#local patch=${arr[2]}; patch=${patch#?}
local branch=$(cat $hg_root/branch 2>/dev/null)
local bookmark=$(cat $hg_root/bookmarks.current 2>/dev/null)
local patch=$(cat $hg_root/patches/status 2>/dev/null | tail -n 1 | sed "s/.*://g")

# hack to get the repo directory name into PS1
if ! [ -d "$(pwd)/.hg" ]; then
#  PS1=$(echo $PS1 | sed 's|^\([^:]*:\)|\1'$hg_repo'.|g') #not sure how to colour hg_repo properly
  PS1=$(echo $PS1 | sed 's|^\([^:]*:..........\)|\1'$hg_repo'/.../|g') # not sure how to escape format
fi

if [ -n "$bookmark" -a -n "$patch" ]; then # both exist
  PS1+="[${BBLUE}$branch${BBLACK}:${BWHITE}$bookmark${BBLACK};${BWHITE}$patch${DF}]\n"
elif [ -n "$patch" ]; then # only patch
  PS1+="[${BBLUE}$branch${BBLACK};${BWHITE}$patch${DF}]\n"
else # only bookmark
  PS1+="[${BBLUE}$branch${BBLACK}:${BWHITE}$bookmark${DF}]\n"
fi
fi
}

function git_prompt
{
local DF='\[\e[0m\]'
local branch=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
if [ -n "$branch" ]; then
  # remove newline 
  if [[ $(expr substr $PS1 $((${#PS1}-1)) 2) == '\n' ]]; then
    PS1=$(expr substr $PS1 1 $((${#PS1}-2)))
  fi
  # append git bits to prompt
  PS1+="[${BROWN}$branch${DF}]\n"
fi
}

# Custom functions
##################

# toggle key bindings between laptop keyboard and real keyboard         
# only difference at the moment is that alt-gr is mapped                
# to ctrl on laptop, but alt on desktop                                 
togglekb(){                                                             
  if [ -z $KB ] || [[ $KB == "laptop" ]]; then                          
    # change to desktop                                                 
    export KB="desktop"                                                 
  else                                                                  
    export KB="laptop"                                                  
  fi                                                                    
  if [ $KB == "desktop" ]; then                                         
    echo "desktop keyboard"
    # assign altgr to ctrl
    xmodmap -e "remove Control = Control_R"
    xmodmap -e "keycode 108 = Control_R"
    xmodmap -e "add Control = Control_R"
    # map context menu key to windows/super key
    xmodmap -e "keycode 135 = Super_L NoSymbol Super_L"

  else
    echo "laptop keyboard"
    # assign altgr to super? >:(
    #xmodmap -e "keycode 108 = Alt_L NoSymbol Super_L"
    xmodmap -e "keycode 108 = Alt_L NoSymbol Alt_L"
  fi
}

# remove ugly gnome term window?
#if [ "$TERM" = "xterm-256color" ]; then
#  xprop -id $(xdotool getactivewindow) -f _MOTIF_WM_HINTS 32c -set _MOTIF_WM_HINTS "0x2, 0x0, 0x0, 0x0, 0x0"
#fi


# /.bashrc

