let
    pkgs = import <nixpkgs> { };
    lib = pkgs.lib;
    stdenv = pkgs.stdenv;
in pkgs.mkShell {
    buildInputs = with pkgs; [
    ];
    shellHook =
    ''
        # source ./git-init.sh;
        alias aplay="bash ~/infra/playbook.sh ";
        alias aencrypt="ansible-vault encrypt vault.yaml --output vault/vault.yaml";
        alias adecrypt="ansible-vault decrypt vault/vault.yaml --output vault.yaml";
        alias rge="rg -g '!{**/migrations/*.py,**/node_modules/**,**/*.json,**/*.csv}'";
        alias rger="rg -g '!{**/migrations/*.py,**/node_modules/**,**/*.json,**/*.csv,**/*.R}'";
    '';

}
