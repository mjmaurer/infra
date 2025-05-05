{ config, pkgs, lib, ... }:

{
  imports = [ ./linux.nix ];

  modules.commonShell = { };

  home.activation.cloneInfra = lib.hm.dag.entryAfter [ "writeBoundary" ] {
    text = ''
      if [ ! -d "$HOME/infra/.git" ]; then
        echo "Cloning infra repo into $HOME/infra"
        git clone https://github.com/mjmaurer/infra "$HOME/infra"
      fi
    '';
    deps = [ pkgs.git ];
  };
}
