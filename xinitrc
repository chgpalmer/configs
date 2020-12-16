# initialise X resource database
xrdb -load ~/.Xresources

# needed to fix dpi for i3wm
xrandr --dpi 220

# change pointer speed, and add middle button click
#xinput set-prop 11 274 1 # libinput: ?none?
#xinput set-prop 11 282 1 # libinput: drag lock enabled
xinput set-prop 11 278 1 # libinput: tapping enabled

if lsusb -d413c:2113; then
  # assign altgr to alt [desktop]
  setxkbmap -layout gb
  setxkbmap -option caps:swapescape
  xmodmap -e "clear mod5";
  xmodmap -e "keycode 108 = Alt_L"
  # map context menu key to windows/super key
  xmodmap -e "keycode 135 = Super_L NoSymbol Super_L"
else
  # use special keyboard layout [laptop]
  # see: /usr/share/X11/xkb/symbols/hpenvy13
  setxkbmap -layout hpenvy13
fi

if ! ps -ef | grep -E "[0-9] python3 .*focus-last.py"; then
  ~/.config/i3/focus-last.py &
fi
