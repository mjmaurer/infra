# ---------------------------------------------------------------------------- #
#                                 Bind / Unbind                                #
# ---------------------------------------------------------------------------- #

# ---------------------------------- Unbinds --------------------------------- #
# Unbind all Alt key bindings (here were the defaults)
# "^[^[" fuck-command-line
# "^[," _history-complete-newer
# "^[/" _history-complete-older
# "^[OA" up-line-or-beginning-search
# "^[OB" down-line-or-beginning-search
# "^[OC" vi-forward-char
# "^[OD" vi-backward-char
# "^[OF" end-of-line
# "^[OH" beginning-of-line
# "^[[1;5C" forward-word
# "^[[1;5D" backward-word
# "^[[200~" bracketed-paste
# "^[[3;5~" kill-word
# "^[[3~" delete-char
# "^[[5~" up-line-or-history
# "^[[6~" down-line-or-history
# "^[[A" up-line-or-beginning-search
# "^[[B" down-line-or-beginning-search
# "^[[C" vi-forward-char
# "^[[D" vi-backward-char
# "^[[Z" reverse-menu-complete
# "^[c" fzf-cd-widget
# "^[~" _bash_complete-word
# Unbind all Alt key bindings
# Alt keys
bindkey -r '^[f' '^[a' '^[i' '^[m' '^[o' '^[,' '^[.' '^[/' '^[c' '^[^['
# Needed for git-fzf
bindkey -r '^g'

# vi mode (needs to come before vi-mode plugin)
# Alternative: https://www.reddit.com/r/vim/comments/60jl7h/zsh_vimode_no_delay_entering_normal_mode/
KEYTIMEOUT=1 # 10ms
bindkey -rM viins '^X'
# bindkey -rM viins '^['
bindkey -v

# ----------------------------------- Binds ---------------------------------- #
# https://nixos.wiki/wiki/Zsh
bindkey "''${key[Up]}" up-line-or-search


# ---------------------------------------------------------------------------- #
#                                Local Settings                                #
# ---------------------------------------------------------------------------- #

path+="$HOME/.local/bin"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
