#  . ~/.nix-profile/etc/profile.d/nix.sh

if [ "$MACHINE_NAME" = "smac" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
