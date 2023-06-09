curl -L https://nixos.org/nix/install | sh
mkdir -p ~/.config
# From mjmaurer/nix-home 
ln -s `pwd` ~/.config/nixpkgs
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
# Might have to run the following or reboot
# export NIX_PATH=$HOME/.nix-defexpr/channels_root${NIX_PATH:+:}$NIX_PATH
# export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
nix-shell '<home-manager>' -A install


# Make more configs as appropriate. Remember to reopen the shell
home-manager -f ~/.config/nixpkgs/machines/hoss.nix switch -b backup
