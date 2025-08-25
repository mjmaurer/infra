
# ------------------------------------ Defaults ----------------------------------- #
# Sourced first 

# https://askubuntu.com/questions/441744/pressing-enter-produces-m-instead-of-a-newline
stty sane

# ------------------------------------ FD ----------------------------------- #

export FD_DEFAULT_OPTS="--hidden --follow --exclude .git"
fd() {
  if [ -n "$ZSH_VERSION" ]; then
    command fd ${=FD_DEFAULT_OPTS} "$@"
  else
    command fd ${FD_DEFAULT_OPTS} "$@"
  fi
}

# ------------------------------------ RG ----------------------------------- #

export RG_DEFAULT_OPTS="--color=always --smart-case --hidden --glob=!.git/"
rg() {
  if [ -n "$ZSH_VERSION" ]; then
    command rg ${=RG_DEFAULT_OPTS} "$@"
  else
    command rg ${RG_DEFAULT_OPTS} "$@"
  fi
}

# ------------------------------------ FZF ----------------------------------- #

export VSCODE="code"
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'
export FZF_ALT_C_COMMAND="" # Disable
export FZF_COMPLETION_TRIGGER=","
export FZF_DEFAULT_OPTS="
  --bind='pgdn:preview-half-page-down'
  --bind='pgup:preview-half-page-up'
"

# These are needed because fzf uses them to generate completions (it can't use FZF_DEFAULT_COMMAND)
_fzf_compgen_dir() {
  fd --type d . "$1"
}
_fzf_compgen_path() {
  fd . "$1"
}
