# ------------------------------------ WSL ----------------------------------- #

inwsl=$(test -f /proc/version && grep Microsoft /proc/version)
if [ ! -z "$inwsl" ]; then
    export DISPLAY=:0.0
fi
cpwin() { cp -r -- "$1" "$WIN_DOWNLOADS"; }
cpfwin() { cp -r -- "${WIN_DOWNLOADS}${1}" "."; }