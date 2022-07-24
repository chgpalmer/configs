#2345678901234567890123456789012345678901234567890123456789012345678901234567890
################################################################################
# .bashrc
################################################################################
# Sources:
# https://www.ukuug.org/events/linux2003/papers/bash_tips/

# this allows passing arbitrary commands to be executed, useful for magic sshing!
if ! [ -z $_BASHRC_CUSTOM_CMD ]; then
  eval $_BASHRC_CUSTOM_CMD
fi

# Colouring command line things
##################################################
#alias template='function __myalias() { if  >/dev/null 2>&1; then  $@; else  $@; fi; unset -f __myalias; }; __myalias'
alias sudo='sudo ' # makes sudo xyz also alias
#alias grep='grep --color=auto --exclude={TAGS,tags} --exclude-dir={build,.hg,.git}'
if ! echo blah | grep blah --exclude-dir=blah 1>/dev/null 2>/dev/null; then # old grep, e.g GNU grep 2.5.1
  alias grep_exclude='grep --exclude={TAGS,tags,*#*#} '
else
  alias grep_exclude='grep --exclude={TAGS,tags,*#*#} --exclude-dir={build,.hg,.git,doc} '
fi
alias gr='grep_exclude --color=always -r' #some servers don't like recursive aliasing
alias grepc='grep_exclude --color=always'
grepl () { grepc --line-buffered $* | less -R; }
alias egrep='egrep --color=auto'
alias egrepc='egrep --color=always'
#alias find='find -not \( -path */.hg -prune \) -not \( -path */.git -prune \) -not \( -path */build -prune \) -not \( -path */doc -prune \)'
function ffind
{
  echo ARGS = $@
  options='-not \( -path */.hg -prune \) -not \( -path */.git -prune \) -not \( -path */build -prune \) -not \( -path */doc -prune \)'
  options='-not ( -path */.hg -prune ) -not ( -path */.git -prune ) -not ( -path */build -prune ) -not ( -path */doc -prune )'

  if [ "$#" -eq 2 ]; then # assume no path
    echo find $options "$1 $2"
    find $options "$1 $2"
  elif [ "$#" -gt 2 ]; then # assume path
    echo find $1 $options "${@:2}"
    find $1 $options "${@:2}"
  else
    echo find "$@"
    find "$@"
  fi
  # when a path isn't entered we want
}
killwindow(){
  blah=`xprop _NET_WM_PID | cut -d' ' -f3`;
  re='^[0-9]+$';
  if ! [[ $blah =~ $re ]] ; then
    echo "error: Not a number" >&2;
    exit 1;
  fi;
  echo "murdering process $blah"
  kill -9 $blah;
};
alias psef="ps -ef | head -n1; ps -ef $@"
alias findb='find -not \( -path */.hg -prune \) -not \( -path */.git -prune \) -not \( -path */doc -prune \)'
alias less='less -R'              # print ANSI colours when piped from grepc
alias la='ls -lah --color=tty'
alias l='ls -lh --color=tty'
alias ll='ls -lhrt --color=tty'
alias lll='ls -lhrt --color=always | less'
alias ls='ls --color=tty'
alias tree='tree -C'
alias tree1='tree -C -L 1'
alias tree2='tree -C -L 2'
alias tree3='tree -C -L 3'
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' # colour gcc v4.9+
alias g++="g++ -fdiagnostics-color=always"

alias vi='vim'
#alias vim='if $(hash gvim 2>/dev/null); then gvim; else vim; fi;'
#alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
#alias ssh='ssh -X'
#alias ssh="$HOME/bin/sshwait" 
alias vimt='vim -c "NERDTree" $1'
alias cdif='diff --color=always'
if $(hash colordiff 2>/dev/null); then alias cdiff='colordiff'; fi
alias hglog='hg log --style compact -G'
alias gshow="git show"
alias gdif="git diff"
alias gstag="git diff --staged"
alias gpull="git pull --rebase"
alias gcom="git commit"
alias gammend="git commit --amend"
alias greb="git rebase"
alias grebi="git rebase -i"
alias gitlog="git log --graph --all --decorate --color"
alias glog="git log --graph --all --decorate --color"
alias glogp="git log --graph --all --decorate --color -p"
alias glogme="git log --graph --all --decorate --color --author $USER"
alias gitlong='git log --stat'
alias gitqrefresh='git commit -a --fixup HEAD; git rebase -i --autosquash HEAD~2'
alias sume="su -c '/bin/bash --rcfile $HOME/.bashrc -i'"
alias dd='function __myalias() { if dd if=/dev/zero of=/dev/zero bs=1MB count=1 status=progress >/dev/null 2>&1; then dd status=progress $@; else dd $@; fi; unset -f __myalias; }; __myalias'
alias dateF="date +\"%Y-%m-%d_%H-%M\""
alias rebash="unalias -a; source $HOME/.bashrc"
alias rebashrc="unalias -a; source $HOME/.bashrc"
alias tailend='ls -rt -1 | tail -n1'
alias lynx='lynx -accept_all_cookies -vikeys -number_links'
alias glynx='lynx -accept_all_cookies google.com -vikeys -number_links'
alias hgcommitlist='hg log --template "{author|person}\n" | sort | uniq -c | sort -nr'
alias src='cd $HOME/src; if [ $(ll | wc -l) -gt 20 ]; then ll | head -n20; echo "..."; else ll; fi'

scr () {
  host_name=$1
  screen_name=$2
  if ! [ -z $DESKTOP_SESSION ] || ! [ -z $_SSH_FROM_GUI ]; then
    ssh $host_name -t "_SSH_FROM_GUI=1 SCREEN_NAME=$screen_name screen -DR" $screen_name
  else
    ssh $host_name -t "SCREEN_NAME=$screen_name screen -DR" $screen_name
  fi
}

# Do once things
##################################################
shopt -s checkwinsize # stops the prompt occasionally eating itself
shopt -s histappend # append session HIST to HISTFILE, possibly not needed with 'history -a' in PROMPT_COMMAND, but it won't hurt
HISTSIZE=20000 # history lines available in session
HISTFILESIZE=100000 # total history lines stored
HISTCONTROL=ignoredups # dont store line if same as prev (session) line

export PATH=$PATH:$HOME/.local/bin

# Do machine specific stuff if file exits
##################################################
if [ -f $HOME/.bash_x ]; then
  source $HOME/.bash_x
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

  # my ssh script sets _SSH_FROM_GUI when sshing from a desktop or from somewhere that already has this flag set
  if ! [ -z $DESKTOP_SESSION ] || ! [ -z $_SSH_FROM_GUI ]; then
    if ! [ -z $STY ]; then
      echo -ne "\033]0;screen: "$(echo $STY | cut -d "." -f2)" ~ host: $(hostname)\007" # terminal title = screenname
    elif ! [ -z $SCREEN_NAME ]; then
      echo -ne "\033]0;screen: $SCREEN_NAME ~ host: $(hostname)\007" # terminal title = screenname
    else
      echo -ne "\033]0;$(hostname)\007" # terminal title = hostname
    fi
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
local hg_exist=$($HOME/.local/bin/find_hg 2>/dev/null) # 2>... as uklogin shouts about about stale NFS handles
if [ -n "$hg_exist" ]; then
local hg_root=$hg_exist"/.hg/"
local hg_repo=$(echo $hg_exist | sed 's|.*/||g')
local DF='\[\e[0m\]'
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

alias dateFS='date +"%Y-%m-%d_%H-%M-%S"'

hexseq () {
  seq $@ | while read i; do
    echo "obase=16; ibase=10; $i" | bc | tr '[:upper:]' '[:lower:]'; 
  done
}

# Dump the TLP header log for a function along with related AER fields #79254
tlpdump () {
  if [ -z $1 ]; then 
    echo "need BDF as first arg"
    return 1
  fi;
  BDF=$1;
  lspci -s $BDF -vv 2>/dev/null | grep -E "(DevSta|UE|CE|AERCap)" | sed 's/^[[:space:]]*//g' | grep -E --color=always "($|[^ ][a-zA-Z]*\+)"
  echo "BDF       offset   data";
  echo "===       ======   ====";
  # tlp header dump is only 16 bytes, and we want to read this in dwords.. = 4 dwords
  hexseq 28 4 43 | while read off; do echo $BDF - ECAP_AER+$off : $(setpci -s $BDF ECAP_AER+0x$off.l); done;

}

# C include tree graphs.
# the hard bit is including all the necessary files
itree () { #indirected graph with c and h files as separate nodes
  rm /tmp/includetree.png 2>/dev/null
  if [ -z $1 ]; then 
    DPI=150
  else
    DPI=$1
  fi;
  # get correct include paths (just get everything up to previous .hg or .git)
  path=""
  find_repo=$(find_repo)
  if ! [ -z $find_repo ]; then
    include_base=$find_repo;
    inbetween=$(pwd -P | sed "s|$include_base||g")
    IFS="/" read -ra PARTS <<< "$inbetween"
    for i in "${PARTS[@]}"
    do
      path=$path,"$include_base/$i"
    done
    # also add the same thing but with "include" stuck on the end, stuff often hides in include leaves
    for i in "${PARTS[@]}"
    do
      path=$path,"$include_base/$i/include"
    done
  fi
  if ! [ -z $path ]; then path="--include $path"; fi
  # create graph
  #echo "$HOME/scripts/cinclude2dot $path 2>/dev/null  | sed 's|\(->.*\)|\1 [dir=back]|g' | neato -Gdpi=$DPI -Tpng -o /tmp/includetree.png 2>/dev/null"
  $HOME/scripts/cinclude2dot $path 2>/dev/null  | sed 's|\(->.*\)|\1 [dir=back]|g' | neato -Gdpi=$DPI -Tpng -o /tmp/includetree.png 2>/dev/null 
  # view graph
  feh --scale-down --auto-zoom /tmp/includetree.png 
}
itree2 () { #indirected graph with c and h files merged to one node
  if [ -z $1 ]; then 
    DPI=100
  else
    DPI=$1
  fi;
  $HOME/scripts/cinclude2dot --merge module 2>/dev/null  | sed 's|\(->.*\)|\1 [dir=back]|g' | neato -Gdpi=$DPI -Tpng 2>/dev/null -o /tmp/includetree.png
  feh --scale-down --auto-zoom /tmp/includetree.png 
}
itree3 () { #directed graph
  if [ -z $1 ]; then 
    DPI=150
  else
    DPI=$1
  fi;
  $HOME/scripts/cinclude2dot 2>/dev/null  | sed 's|\(->.*\)|\1 [dir=back]|g' | dot -Gdpi=$DPI -Tpng 2>/dev/null -o /tmp/includetree.png
  feh --scale-down --auto-zoom /tmp/includetree.png 
}

# completion with unsupported request bit set...
tlp () {
  if [ -z $1 ]; then 
    echo "feed me a hex DWORD such as 0x1a810019"
    return 1
  fi;
  DW=$1
  echo "$DW:"
  python -c "print '  Type   : ' + str( bin( ($DW >> 24) & 0x1f ) )" # Type
  python -c "print '  Fmt    : ' + str( bin( ($DW >> 29) ) )" # Fmt
  python -c "print '  CmpSta : ' + str( bin( ($DW >> 13) & 0x1f) )" # Completion Status
}

#find type and format of all tlp headers
#tlpdump "01:00.0" | grep 100 | cut -d " " -f5 | while read DW; do tlp "0x$DW"; done;

#https://sakshamsharma.com/2019/03/i3-wsl/
#export DISPLAY=localhost:0

# stuff commandline into clipboard
function xcp(){
  echo "$@" | xclip -selection clipboard
}

function githelp(){
 local helpz="
 update all submodules:
   git submodule update --init --recursive

 create new branch:
   git checkout -b <NEW_BRANCH>

 move branch to commit:
   git branch -f <BRANCH> <COMMIT>

 remove all changes in working direcotry
   git checkout .

 move changes from staging to working directory:
   git reset

 update the most recent commit with local changes:
   git add -u
   git commit --amend

 interactively split a patch:
   tig

 modify your commit queue:
   git rebase -i HEAD~10 # or some suitable number of past commits you want to trawl through
   # foreach
     vim files-to-change
     git add -u && git commit --amend
     git rebase --continue

 rebase your local branch [JIRA-401] against some upstream branch [dev]:
   git checkout dev && git pull # update your main branch
   git rebase dev JIRA-401     # rebase your local branch onto your main branch

 origin/master has diverged, and you want to rebase local master onto it
   git rebase origin/master master

 post a review
   rbt post <CHANGESET>
 update a review
   rbt post -u [-r <RB_NUM>]
 "
 echo "$helpz"|less
}

function gitbranch(){
  for k in `git branch | perl -pe s/^..//`; do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k -- | head -n 1`\\t$k; done | sort -r
}
# /.bashrc

