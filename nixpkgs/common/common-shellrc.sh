# Meant to be compatible with bash and zsh

# Load home manager session variables (XDG_CONFIG_HOME, etc.)
# The unset is a hack to source the file multiple times as needed
unset __HM_SESS_VARS_SOURCED ; . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

# ------------------------------ Local Settings ------------------------------ #
if [ -n ~/.config/local_bash_env ]; then
    # Make sure to use 'export' in the local_bash_env file
    source ~/.config/local_bash_env
fi

# --------------------------------- functions -------------------------------- #
dexec() {
    docker exec -it "$1" /bin/bash
}

vscode_tmux_nix() {
    # Variables
    DIR_PATH=$1
    SESSION_NAME=$(basename $DIR_PATH)
    WINDOW_NAME="vscode"
    # TODO: Change to $SHELL after moving to nixos
    COMMAND="zsh -c 'if [ -f \"${DIR_PATH}/shell.nix\" ]; then nix-shell --command \"zsh\" \"${DIR_PATH}/shell.nix\"; else zsh; fi'"

    echo $SESSION_NAME
    # Check if the tmux session exists
    if tmux has-session -t $SESSION_NAME 2>/dev/null; then
        echo "exists"
        tmux new-window -t $SESSION_NAME -n $WINDOW_NAME "$COMMAND"
    else
        tmux new-session -d -s $SESSION_NAME -n $WINDOW_NAME "$COMMAND"
    fi
    tmux attach-session -t $SESSION_NAME
}

# ------------------------------------ WSL ----------------------------------- #

inwsl=$(test -f /proc/version && grep Microsoft /proc/version)
if [ ! -z "$inwsl" ]; then
    export DISPLAY=:0.0
fi
cpwin() { cp -r -- "$1" "$WIN_DOWNLOADS"; }
cpfwin() { cp -r -- "${WIN_DOWNLOADS}${1}" "."; }
