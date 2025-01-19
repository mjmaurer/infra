# ------------------------------------ FZF: Ripgrep ------------------------------------ #

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