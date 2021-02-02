# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export QEMU_AUDIO_DRV=alsa
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# Set variable to describe environment used in other config files
# E.g laptop, desktop, work, etc
if ps -ef | grep -E "[0-9] /opt/Citrix/VDA/bin/"; then
  export _CONFIG_ENV_TYPE=work
elif [ `xrandr | grep \* | cut -d' ' -f4` == 3200x1800 ]; then
  export _CONFIG_ENV_TYPE=laptop
fi
