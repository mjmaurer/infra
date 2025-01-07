{ pkgs, lib, config, derivationName, ... }:
let
  inherit (config.home) packages;
in
{
  options.modules.commonShell = {
    # TODO: remove
    machineName = lib.mkOption {
      type = lib.types.str;
      description = ''
        RC common to all shells. Should be compatible 
      '';
      default = "unset";
      readOnly = true;
    };
    # TODO: Probably don't need this and initExtra
    rc = lib.mkOption {
      default = builtins.readFile ./common-shellrc.sh;
      type = lib.types.str;
      description = ''
        RC common to all shells. Should be compatible 
      '';
    };
    dirHashes = lib.mkOption {
      default = { };
      type = lib.types.attrs;
      example = { code = "$HOME/code"; };
      description = ''
        A set of directory hashes.
        Only works for zsh right now.
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
    xdg.dataFile = {
      "nix-templates/flake-template.nix" = {
        source = ./nix/flake-template.nix;
      };
    };
    home.packages = [
      (pkgs.writeScriptBin "new-nix-shell" (builtins.readFile ./nix/new-nix-shell.sh))
      (pkgs.writeScriptBin "new-nix-flake" (builtins.readFile ./nix/new-nix-flake.sh))
      (pkgs.writeShellScriptBin "pydbw" ''
        echo "python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client $@"
        echo "Use 'pydb -m' for modules"
        echo "May need to activate venv\n"
        echo "Waiting for debugger to attach..."
        exec python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client "$@"
      '')
      (pkgs.writeShellScriptBin "pydb" ''
        echo "python -Xfrozen_modules=off -m debugpy --listen 5678 $@"
        echo "Use 'pydb -m' for modules"
        echo "May need to activate venv"
        exec python -Xfrozen_modules=off -m debugpy --listen 5678 "$@"
      '')
    ];
    modules.commonShell = {
      initExtraFirst = ''
        # --------------------------------- FZF-Git --------------------------------
        source ${./fzf/fzf-git.sh}
        source ${./fzf/fzf-docker.sh}
        source ${./fzf/fzf-search-alias.sh}
      '';
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        BOBBY_PORT = 7850;
        AUTOMATIC_PORT = 7860;
        RVC_PORT = 7865;
        PLEX_WEB_PORT = 32400;
        JELLYFIN_WEB_PORT = 8096;
        DERIVATION_NAME = derivationName;
        # .git would otherwise be hidden
        FD_DEFAULT_OPTS = "--hidden --follow --exclude .git";
        RG_DEFAULT_OPTS = "--color=always --smart-case --hidden --glob=!.git/";
      };
      dirHashes = { };
      shellAliases = {
        ".." = "cd ..";
        "cat" = "bat --plain --color=always";
        "t" = "tree --gitignore";
        "ta" = "tree --gitignore -a";
        "rn" = "npm run";
        "rnx" = "npx";
        "ry" = "yarn";
        "rp" = "poetry run";
        "ndr" = "nix-direnv-reload";
        "dr" = "direnv reload";
        "da" = "direnv allow";
        "gp" = "git push";
        "gc" = "git commit -v";
        "gsh" = "_fzf_git_show";
        "gd" = "_fzf_git_diff";
        "gad" = "_fzf_git_all_diffs";
        "gcs" = "git commit -v --gpg-sign";
        "ga" = "git add $(_fzf_git_files)";
        "gaf" = "git add $(_fzf_git_files)";
        "gaa" = "git add --all";
        "gac" = "gaf && gcai"; # gcai is defined in git-commit-ai.sh
        "gs" = "git status";
        "gsf" = "git status $(_fzf_git_files)";
        "gle" = "git_local_exclude";
        "poe" = "poetry run poe";
        # "rgi" = "rgi"; For visibility. Defined in common-shellrc.sh
        # "rgf" = "rgf"; For visibility. Defined in common-shellrc.sh
        "s" = "rgt";
        "as" = "print -z $(_fzf_search_alias)";
        "nix-shell" = "nix-shell --command 'zsh'";
        "ns" = "nix-shell";
        "nd" = "nix develop --command 'zsh'";
        "ndu" = "nix flake update";
        "nrbnoreload" = lib.mkDefault "nixos-rebuild switch --show-trace --flake ~/infra";
        "nrb" = ''
          nrbnoreload;
          source ~/.zshrc
        '';
        "nns" = "new-nix-shell";
        "nnf" = "new-nix-flake";
        "nps" = "nix-search";
        "nss" = "ls -1 /nix/store | grep";
        "nsd" = "nix-store --delete";
        "la" = lib.mkDefault "ls -a --color=auto";
        "ls" = lib.mkDefault "ls --color=auto";
        "py" = "python";
        "pyvenv" = "python -m venv";
        "pyva" = "source .venv/bin/activate";
        "pyda" = "deactivate";
        "pipr" = "pip install -r ";
        # TODO: We could instead specify each hostname in the flake.nix
        # It will use that for switch when no derivation is specified
        # 'noload' because you need to source the shell afterwards (which `hmswitch` does)
        "hmswitchnoload" = "nix run home-manager/master -- switch --flake ~/infra#${derivationName}";
        # `hmswitch` is defined per-shell
        "hms" = "hmswitch"; 
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
