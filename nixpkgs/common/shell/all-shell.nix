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
    # TODO: Probably don't need this and initExtra
    rc = lib.mkOption {
      default = builtins.readFile ./all-shellrc.sh;
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
    initExtraFirst = lib.mkOption {
      default = "";
      type = lib.types.lines;
      description = ''
        Extra commands that should be run when initializing an
        interactive shell.
      '';
    };
    initExtraLast = lib.mkOption {
      default = "";
      type = lib.types.lines;
      description = ''
        Extra commands that should be run when initializing an
        interactive shell.
      '';
    };
    assembleInitExtra = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = shellSpecificFile: ''
        ${config.modules.commonShell.initExtraFirst}
        ${config.modules.commonShell.rc}
        ${builtins.readFile shellSpecificFile}
        ${config.modules.commonShell.initExtraLast}
      '';
      description = ''
        A function that assembles the initExtra string.
        It takes a path to a shell-specific file as an argument.
      '';
    };
  };

  config = {
    xdg.configFile = {
      "local_bash_env.example" = {
        source = ./local_bash_env.example;
      };
    };
    modules.commonShell = {
      initExtraFirst = ''
        # --------------------------------- FZF-Git --------------------------------
        source ${./fzf-git.sh}
        source ${./fzf-docker.sh}
      '';
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        BOBBY_PORT = 7850;
        AUTOMATIC_PORT = 7860;
        RVC_PORT = 7865;
        PLEX_WEB_PORT = 32400;
        JELLYFIN_WEB_PORT = 8096;
        MACHINE_NAME = config.modules.commonShell.machineName;
         # .git would otherwise be hidden
        FD_DEFAULT_OPTS = "--hidden --follow --exclude .git";
        RG_DEFAULT_OPTS = "--color=always --smart-case --hidden --glob=!.git/";
      };
      shellAliases = {
        ".." = "cd ..";
        "cat" = "bat";
        "gc" = "git commit -v";
        "gcs" = "git commit -v --gpg-sign";
        "ga" = "git add $(_fzf_git_files)";
        "gaf" = "git add $(_fzf_git_files)";
        "gaa" = "git add --all";
        "gac" = "gaf && gcai"; # gcai is defined in git-commit-ai.sh
        "gs" = "git status";
        "gsf" = "git status $(_fzf_git_files)";
        # "rgi" = "rgi"; For visibility. Defined in all-shellrc.sh
        # "rgf" = "rgf"; For visibility. Defined in all-shellrc.sh
        "nix-shell" = "nix-shell --command 'zsh'";
        "ns" = "nix-shell";
        "la" = lib.mkDefault "ls -a --color=auto";
        "ls" = lib.mkDefault "ls --color=auto";
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