# xbindkeys -k to see what a key/key combo is
# xev lets you see key codes

# this calls the "custom" layout (/usr/share/X11/kbd/symbols/custom)
# if that doesn't exist, make one! ...:
# default  partial alphanumeric_keys modifier_keys
# xkb_symbols "basic" {
#   include "gb"
#   key <MENU> { [ Super_R ] };
#   key <RALT> { type[Group1] = "TWO_LEVEL",
#                symbols[Group1] = [ Alt_R, Alt_R ] };
#   include "capslock(swapescape)"
# };
if ! setxkbmap -layout custom; then
  setxkbmap -layout gb
fi

# i3 extension that runs in the background and remembers your prev workspace
# then in i3 config you bind to `focus-last.py --switch` to go back :)
if ! ps -ef | grep "python3.*.config/i3/focus-last.py" | grep -v "grep"; then
  python3 ~/.config/i3/focus-last.py &
fi
