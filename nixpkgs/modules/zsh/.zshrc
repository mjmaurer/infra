# Alternative: https://www.reddit.com/r/vim/comments/60jl7h/zsh_vimode_no_delay_entering_normal_mode/
KEYTIMEOUT=1 # 10ms
bindkey -rM viins '^X'

# ---------------------------------------------------------------------------- #
#                                 Bind / Unbind                                #
# ---------------------------------------------------------------------------- #

# ---------------------------------- Unbinds --------------------------------- #
# Alt keys
bindkey -r '^[f' '^[a' '^[i' '^[m'
# vi mode (needs to come before vi-mode plugin)
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
