{ lib, config, ... }:
{
  options.modules.commonShell = {
    machineName = lib.mkOption {
      type = lib.types.str;
      description = ''
        RC common to all shells. Should be compatible 
      '';
      readOnly = true;
    };
    rc = lib.mkOption {
      default = builtins.readFile ./common-shellrc.sh;
      type = lib.types.str;
      description = ''
        RC common to all shells. Should be compatible 
      '';
    };
    sessionVariables = lib.mkOption {
      default = { };
      type = lib.types.attrs;
      example = { MAILCHECK = 30; };
      description = ''
        Environment variables that will be set for the Bash session.
      '';
    };
    shellAliases = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.str;
      example = lib.literalExpression ''
        {
          ll = "ls -l";
          ".." = "cd ..";
        }
      '';
      description = ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to command strings or directly to build outputs.
      '';
    };
    initExtra = lib.mkOption {
      default = "";
      type = lib.types.lines;
      description = ''
        Extra commands that should be run when initializing an
        interactive shell.
      '';
    };
  };

  config = {
    modules.commonShell = {
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        BOBBY_PORT = 7850;
        AUTOMATIC_PORT = 7860;
        RVC_PORT = 7865;
        PLEX_WEB_PORT = 32400;
        JELLYFIN_WEB_PORT = 8096;
        MACHINE_NAME = config.modules.commonShell.machineName;
      };
      shellAliases = {
        ".." = "cd ..";
        "gc" = "git commit -v";
        "gcs" = "git commit -v --gpg-sign";
        "ga" = "git add --all";
        "gs" = "git status";
        "rg" = "rg --hidden --glob=!.git/ -g '!{**/node_modules/**,venv/}'";
        "nix-shell" = "nix-shell --command 'zsh'";
        "ns" = "nix-shell";
        "la" = lib.mkDefault "ls -a";
        "ls" = lib.mkDefault "ls";
        "hmswitchnoload" = "home-manager -f ~/.config/nixpkgs/machines/$MACHINE_NAME.nix switch -b backup";
        "dtail" = "docker logs -tf --tail='50'";
        "dstop" = "docker stop `docker ps -aq`";
        "dlog" = "docker logs ";
        "dtop" = "docker run --name ctop  -it --rm -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop";
        "dps" = "docker ps ";
        "dcrneup" = "docker compose up -f ~/docker-compose.yml -d ";
        "dcup" = "docker compose up -d ";
        "dcreup" = "docker compose up -d --build --force-recreate ";
        "drm" = "docker rm `docker ps -aq`";
        "dcp" = "docker compose -f ~/docker-compose.yml ";
        "dcporph" = "docker compose -f ~/docker-compose.yml --remove-orphans ";
      };
    };
  };
}
