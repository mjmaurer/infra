{ osConfig ? null, pkgs, lib, config, derivationName, ... }:
let
  inherit (config.home) packages;
  templateFile = "${config.xdg.dataHome}/nix-templates/flake-template.nix";
  cfg = config.modules.commonShell;
in {
  options.modules.commonShell = {
    enableBash = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    enableZsh = lib.mkOption {
      type = lib.types.bool;
      default = true;
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
    enableShellTmuxTimeout = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = ''
        Enables a shell timeout that will also
        kill any tmux sessions that the shell is currently in. 
      '';
    };
    assembleInitExtra = lib.mkOption {
      type = lib.types.functionTo lib.types.str;
      default = shellSpecificFile: ''
        ${cfg.initExtraFirst}
        ${builtins.readFile shellSpecificFile}
        ${cfg.initExtraLast}
      '';
      description = ''
        A function that assembles the initExtra string.
        It takes a path to a shell-specific file as an argument.
      '';
    };
  };

  imports = [
    # (lib.mkIf cfg.enableBash ./bash/bash.nix)
    # (lib.mkIf cfg.enableZsh ./zsh/zsh.nix)
    ./bash/bash.nix
    ./zsh/zsh.nix
    ./tmux/tmux-file-pick-aid.nix
  ];

  config = {
    modules.bash.enable = cfg.enableBash;
    modules.zsh.enable = cfg.enableZsh;
    home.file = {
      "${templateFile}" = { source = ./nix/flake-template.nix; };
      # Scripts without '.sh' don't contain functions
      # and so are added to .local/bin (and thus the PATH so other programs can find them)
      ".local/bin/tmux_switch_by_name" = {
        source = ./tmux/tmux-switch-by-name;
        executable = true;
      };
      ".local/bin/tmux_pwd" = {
        source = ./tmux/tmux-pwd;
        executable = true;
      };
    };
    modules.commonShell = {
      initExtraFirst = ''
        # Load home manager session variables (XDG_CONFIG_HOME, etc.)
        # The unset is a hack to source the file multiple times as needed
        unset __HM_SESS_VARS_SOURCED ; . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

        ${lib.optionalString (osConfig ? sops
          && builtins.hasAttr "shell.env" osConfig.sops.templates) ''
            # --------------------------------- SOPS Secrets --------------------------------
            source ${osConfig.sops.templates."shell.env".path}
          ''}

        source ${./defaults.sh}

        # --------------------------------- FZF --------------------------------
        for file in ${./fzf}/*.sh; do
          source $file
        done

        # --------------------------------- Misc --------------------------------
        for file in ${./misc}/*.sh; do
          source $file
        done

        # --------------------------------- Language-Specific --------------------------------
        for file in ${./langs}/*.sh; do
          source $file
        done

        # --------------------------------- Nix --------------------------------
        for file in ${./nix}/*.sh; do
          source $file
        done


        ${lib.optionalString (cfg.enableShellTmuxTimeout) ''
          # Timeout shells after 4 days of inactivity (will also kill tmux started with zsh)
          export TMOUT=345600

          kill_tmux_workspace() {
              if [ ! -z "$TMUX" ]; then
                  current_session=$(tmux display-message -p "#{session_name}")
                  # Kill other sessions matching the pattern first
                  tmux list-sessions | grep "^$current_session" | cut -d: -f1 | grep -v "^$current_session$" | xargs -I{} tmux kill-session -t {}
                  # Then kill our own session
                  tmux kill-session -t "$current_session"
              fi
          }

          if [ -n "$ZSH_VERSION" ]; then
              TRAPALRM() {
                  kill_tmux_workspace;
                  exit
              }
          else
              trap 'kill_tmux_workspace; exit' ALRM
          fi
        ''}
      '';
      sessionVariables = {
        NIX_TEMPLATE_FILE = templateFile;
        EDITOR = "nvim";
        VISUAL = "nvim";
        BOBBY_PORT = 7850;
        AUTOMATIC_PORT = 7860;
        RVC_PORT = 7865;
        PLEX_WEB_PORT = 32400;
        JELLYFIN_WEB_PORT = 8096;
        DERIVATION_NAME = derivationName;
        # .git would otherwise be hidden
      };
      dirHashes = { };
      shellAliases = {
        ".." = "cd ..";
        "bat" = "bat --plain --color=always";
        "batl" = "bat --plain --color=always --style numbers";
        "t" = "tree --gitignore";
        "ta" = "tree --gitignore -a";
        "tmd" = "tmux_pwd";
        "tms" = "tmux_switch_by_name";
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
        "nrbnoreload" =
          lib.mkDefault "nixos-rebuild switch --show-trace --flake ~/infra";
        "nrb" = ''
          nrbnoreload;
          exec zsh;
        '';
        "nnf" = "new_nix_flake";
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
        "hmswitchnoload" =
          "nix run home-manager/master -- switch --flake ~/infra#${derivationName}";
        # `hmswitch` is defined per-shell
        "hms" = "hmswitch";
        "dtail" = "docker logs -tf --tail='50'";
        "dstop" = "docker stop `docker ps -aq`";
        "dlog" = "docker logs ";
        "dtop" =
          "docker run --name ctop  -it --rm -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop";
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
