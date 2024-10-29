# Meant to be compatible with bash and zsh

# Load home manager session variables (XDG_CONFIG_HOME, etc.)
# The unset is a hack to source the file multiple times as needed
unset __HM_SESS_VARS_SOURCED ; . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

# ------------------------------ Local Settings ------------------------------ #
if [ -n ~/.config/local_bash_env ]; then
    # Make sure to use 'export' in the local_bash_env file
    source ~/.config/local_bash_env
fi
# ------------------------------------ FD ----------------------------------- #

fd() {
  command fd $FD_DEFAULT_OPTS "$@"
}

# ------------------------------------ RG ----------------------------------- #

rg() {
  command rg $RG_DEFAULT_OPTS "$@"
}

# ------------------------------------ FZF ----------------------------------- #

export VSCODE="cursor"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
export FZF_ALT_C_COMMAND="" # Disable
export FZF_COMPLETION_TRIGGER=","
export FZF_DEFAULT_OPTS="
  --bind='pgdn:preview-half-page-down'
  --bind='pgup:preview-half-page-up'
"

cpf() {
  # Copies a file or directory given a name. Uses FZF to select the file or directory.
  if [ -z "$1" ]; then
    echo "No file or dir name provided"
    return
  fi
  local parent=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select parent directory')
  if [ -z "$parent" ]; then
    echo "No parent directory selected"
    return
  fi
  local to_copy=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to copy')
  if [ -z "$to_copy" ]; then
    echo "No file to copy selected"
    return
  fi
  cp -r "$to_copy" "$parent/$1"
}

mk() {
  # Creates a file or directory given a name. Uses FZF to select the parent directory.
  # It determines whether to create a file or directory based on whether the name ends with a slash.
  local dir=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select parent directory')
  if [ -z "$dir" ]; then
    echo "No directory selected"
    return
  fi
  if [[ "$1" == */ ]]; then
    mkdir -p "$dir/$1"
  else
    touch "$dir/$1"
    # Hacky way to detect if VSCode is running
    if [ -n "$VSCODE_GIT_ASKPASS_MAIN" ]; then
      $VSCODE --goto "$dir/$1"
    fi
  fi
}

mvf() {
  local file=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to move')
  if [ -z "$file" ]; then
    echo "No file or dir selected"
    return
  fi

  local new_dir=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select new parent directory')
  if [ -z "$new_dir" ]; then
    echo "No new parent directory selected"
    return
  fi
  mv "$file" "$new_dir"
}

rename() {
  local file=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to rename')
  if [ -z "$file" ]; then
    echo "No file or dir selected"
    return
  fi

  local new_name
  read -e -i "$(basename "$file")" -p "New name: " new_name
  if [ -z "$new_name" ]; then
    echo "No new name provided"
    return
  fi

  mv "$file" "$new_name"
  echo "Make sure to rename the file elsewhere! Consider using VSCode for this."
}

# These are needed because fzf uses them to generate completions (it can't use FZF_DEFAULT_COMMAND)
_fzf_compgen_dir() {
  fd --type d . "$1"
}
_fzf_compgen_path() {
  fd . "$1"
}

# ripgrep then fzf
rgf() {
    # 1. Search for text in files using Ripgrep
    # 2. Interactively narrow down the list using fzf
    # 3. Open the file in Vim
    rg --color=always --line-number --no-heading --smart-case ${*:-} |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind "enter:become($VSCODE --goto '{1}:{2}')"
}

# ripgrep interactive
# https://github.com/junegunn/fzf/blob/master/ADVANCED.md#using-fzf-as-interactive-ripgrep-launcher
rgi() {
    # 1. Search for text in files using Ripgrep
    # 2. Interactively restart Ripgrep with reload action
    # 3. Open the file in Vim
    SEARCH_QUERY="$1"
    shift
    # Quote remaining arguments and preserve them
    EXTRA_ARGS=$(printf "%q " "$@")

    RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case ${EXTRA_ARGS}"
    fzf --ansi --disabled --query "$SEARCH_QUERY" \
        --bind "start:reload:$RG_PREFIX {q}" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind "enter:become($VSCODE --goto '{1}:{2}')"
}

rgt() {
    # Switch between Ripgrep mode and fzf filtering mode (CTRL-T)
    rm -f /tmp/rg-fzf-{r,f}
    SEARCH_QUERY="$1"
    shift
    EXTRA_ARGS=$(printf "%q " "$@")
    RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case ${EXTRA_ARGS}"
    fzf --ansi --disabled --query "$SEARCH_QUERY" \
        --bind "start:reload:$RG_PREFIX {q}" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --bind 'ctrl-t:transform:[[ ! $FZF_PROMPT =~ ripgrep ]] &&
        echo "rebind(change)+change-prompt(1. ripgrep> )+disable-search+transform-query:echo \{q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r" ||
        echo "unbind(change)+change-prompt(2. fzf> )+enable-search+transform-query:echo \{q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f"' \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --prompt '1. ripgrep> ' \
        --delimiter : \
        --header 'CTRL-T: Switch between ripgrep/fzf' \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind "enter:become($VSCODE --goto '{1}:{2}')"
}

_fzf_git_fzf() {
    # git-fzf default fzf options
    # You can see the original in fzf-git.sh
    fzf --height=50% --tmux 90%,90% \
    --layout=reverse --multi --min-height=20 --border \
    --border-label-pos=2 \
    --color='header:italic:underline,label:blue' \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' \
    "$@"
}

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
        echo "Session exists"
        # Check if the window exists
        if ! tmux list-windows -t $SESSION_NAME -F '#W' | grep -q "^${WINDOW_NAME}$"; then
            echo "Creating new window: $WINDOW_NAME"
            tmux new-window -t $SESSION_NAME -n $WINDOW_NAME "$COMMAND"
        else
            echo "Window $WINDOW_NAME already exists"
        fi
    else
        echo "Creating new session: $SESSION_NAME"
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
