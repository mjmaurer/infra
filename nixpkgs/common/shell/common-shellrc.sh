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
  if [ -n "$ZSH_VERSION" ]; then
    command fd ${=FD_DEFAULT_OPTS} "$@"
  else
    command fd ${FD_DEFAULT_OPTS} "$@"
  fi
}

# ------------------------------------ RG ----------------------------------- #

rg() {
  if [ -n "$ZSH_VERSION" ]; then
    command rg ${=RG_DEFAULT_OPTS} "$@"
  else
    command rg ${RG_DEFAULT_OPTS} "$@"
  fi
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

git_local_exclude() {
  # Add's a file to .git/info/exclude if .git exists
  if [ -z ".git" ]; then
    echo "Git repo not found"
    return
  fi
  local to_exclude=$(fd --strip-cwd-prefix . | fzf --header 'Select file to exclude from git')
  if [ -z "$to_exclude" ]; then
    echo "No file to exclude selected"
    return
  fi
  echo "$to_exclude" >> .git/info/exclude
}

cpf() {
  # Copies a file or directory given a name. Uses FZF to select the file or directory.

  local to_copy=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to copy')
  if [ -z "$to_copy" ]; then
    echo "No file to copy selected"
    return
  fi

  local parent=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select parent directory')
  if [ -z "$parent" ]; then
    echo "No parent directory selected"
    return
  fi

  # Prompt for name via stdin:
  local name
  if [ -n "$ZSH_VERSION" ]; then
    vared -p "Name: " name
  else
    read -p "Name: " -e -i "$name" name
  fi
  if [ -z "$name" ]; then
    echo "No file or dir name provided"
    return
  fi

  # Get extensions (or lack thereof) for both files
  local to_copy_ext="${to_copy##*.}"
  local name_ext="${name##*.}"
  if [[ "$to_copy" != *"."* ]]; then
    to_copy_ext=""
  fi
  if [[ "$name" != *"."* ]]; then
    name_ext=""
  fi
  if [[ "$to_copy_ext" != "$name_ext" ]]; then
    echo "Error: File extensions must match"
    return 1
  fi

  cp -r "$to_copy" "$parent/$name"
}

mkf() {
  local name=$1
  if [ -z "$name" ]; then
    if [ -n "$ZSH_VERSION" ]; then
      vared -p "Name: " name
    else
      read -p "Name: " -e -i "$name" name
    fi
    if [ -z "$name" ]; then
      echo "No file or dir name provided"
      return
    fi
  fi
  # Add trailing slash if no extension and doesn't already end in slash
  if [[ "$name" != *.* ]] && [[ "$name" != */ ]]; then
    name="${name}/"
  fi
  if [ -z "$name" ] || [ "$name" = "/" ]; then
    echo "Name cannot be empty or a single slash"
    return 1
  fi
  # Creates a file or directory given a name. Uses FZF to select the parent directory.
  # It determines whether to create a file or directory based on whether the name ends with a slash.
  local dir=$(fd --type d --strip-cwd-prefix . | fzf --header 'Select parent directory')
  if [ -z "$dir" ]; then
    echo "No directory selected"
    return
  fi
  if [[ "$name" == */ ]]; then
    mkdir -p "$dir/$name"
  else
    touch "$dir/$name"
    # Hacky way to detect if VSCode is running
    if [ -n "$VSCODE_GIT_ASKPASS_MAIN" ]; then
      $VSCODE --goto "$dir/$name"
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

rnf() {
  local file=$(fd --strip-cwd-prefix . | fzf --header 'Select file or dir to rename')
  if [ -z "$file" ]; then
    echo "No file or dir selected"
    return
  fi

  local new_name=$(basename "$file")
  if [ -n "$ZSH_VERSION" ]; then
    vared -p "New name (sure you don't want to use IDE?): " new_name
  else
    read -p "New name (sure you don't want to use IDE?): " -e -i "$new_name" new_name
  fi

  if [ -z "$new_name" ] || [ "$new_name" = "$(basename "$file")" ]; then
    echo "No new name provided or name unchanged"
    return
  fi

  mv "$file" "$(dirname "$file")/$new_name"
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
    COMMAND="zsh -c 'if [ -f \"./flake.nix\" ]; then nix develop --command \"zsh\"; elif [ -f \"./shell.nix\" ]; then nix-shell --command \"zsh\"; else zsh; fi'"

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
