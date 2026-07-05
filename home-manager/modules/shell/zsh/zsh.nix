{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.zsh;
  commonShell = config.modules.commonShell;
in
{
  options.modules.zsh = {
    enable = lib.mkEnableOption "zsh";
    shellGlobalAliases = mkOption {
      type = with types; attrsOf str;
      default = { };
      description = "Global aliases to add to zsh";
    };
  };

  config = lib.mkIf cfg.enable {

    home.file = {
      ".p10k.zsh" = {
        source = ./p10k.zsh;
      };
      # Portable shell script
      ".zsh/shell-scripts/aichat.zsh" = {
        source = ./aichat.zsh;
      };
      # Plugins installed to portable paths (on NixOS these are symlinks to nix store)
      ".zsh/plugins/zsh-powerlevel10k" = {
        source = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
        recursive = true;
      };
      ".zsh/plugins/fzf-tab" = {
        source = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.1.2";
          sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
        };
        recursive = true;
      };
      ".zsh/plugins/zsh-autosuggestions" = {
        source = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
        };
        recursive = true;
      };
      ".zsh/plugins/zsh-syntax-highlighting" = {
        source = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/";
        recursive = true;
      };
    };

    programs.zsh = {
      enable = true;
      package = pkgs.zsh;

      # This actually doesn't do anything since Nix gives
      # oh-my-zsh responsibility for calling compinit
      enableCompletion = true;
      autosuggestion.enable = false;
      syntaxHighlighting.enable = false; # Portable: sourced manually from $HOME/.zsh/plugins/

      dirHashes = commonShell.dirHashes // { };
      sessionVariables = commonShell.sessionVariables // { };
      shellAliases = commonShell.shellAliases // {
        "hig" = "history 0 | grep";
        "hmswitch" = ''
          hmswitchnoload;
          source ~/.zshrc
        '';
      };
      shellGlobalAliases = cfg.shellGlobalAliases // {
        hp = "HEAD~1";
        hpp = "HEAD~2";
        hppp = "HEAD~3";
        # Ripgrep context / copy mode
        rgC = "--no-line-number -A 10 -B 10";
        pbc = "| pbcopy";

        G = "| grep";
        GC = "| grep -C 3";

        # Ripgrep file types
        gPY = "--glob '**/*.py'";
        gNOT_PY = "--glob '!**/*.py'";
        gJS = "--glob '**/*.{js,ts,tsx,jsx}'";
        gNOT_JS = "--glob '!**/*.{js,ts,tsx,jsx}'";
        gCONF = "--glob '**/*.{json,yaml,yml,toml,xml,conf,ini,cfg}'";
        gNOT_CONF = "--glob '!**/*.{json,yaml,yml,toml,xml,conf,ini,cfg}'";
        gJAVA = "--glob '**/*.java'";
        gNOT_JAVA = "--glob '!**/*.java'";
        gJSON = "--glob '**/*.json'";
        gCSV = "--glob '**/*.csv'";
        gR = "--glob '**/*.R'";
        gNOT_R = "--glob '!**/*.R'";
        gNIX = "--glob '**/*.nix'";
        gNOT_NIX = "--glob '!**/*.nix'";
      };

      defaultKeymap = "viins";
      initContent = lib.mkMerge [
        # Source local pre-init config (not managed by Nix)
        (lib.mkOrder 50 ''
          [[ -f "$HOME/.zsh/local.pre.zsh" ]] && source "$HOME/.zsh/local.pre.zsh"
        '')

        (lib.mkBefore ''
          # Show hidden files without needing to type .
          setopt globdots

          VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
          VI_MODE_SET_CURSOR=true
          ZSH_AUTOSUGGEST_STRATEGY=(history)
          # https://github.com/NixOS/nix/issues/1577
          if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          elif [ "$(uname)" = "Darwin" ]; then
            echo "WARNING: nix-daemon.sh not found"
          fi

          [[ -f "$HOME/.zsh/shell-scripts/aichat.zsh" ]] && source "$HOME/.zsh/shell-scripts/aichat.zsh"
          bindkey '^G^G' _aichat_zsh

          # Load theme
          # fpath+=(${pkgs.zsh-powerlevel10k}/share/zsh/site-functions)
          # autoload -U promptinit; promptinit
          # prompt powerlevel10k
        '')

        # Portable HELPDIR override (home-manager sets it to a nix store path)
        (lib.mkOrder 525 ''
          if [[ ! -d "''${HELPDIR:-}" ]]; then
            unset HELPDIR
          fi
        '')

        # Portable dircolors (replaces programs.dircolors.enableZshIntegration)
        (lib.mkOrder 550 ''
          if command -v dircolors &>/dev/null; then
            eval "$(dircolors -b ~/.dir_colors 2>/dev/null)" || true
          fi
        '')

        # Plugin fpath additions (before oh-my-zsh compinit)
        (lib.mkOrder 560 ''
          for _pd in zsh-powerlevel10k fzf-tab zsh-autosuggestions zsh-syntax-highlighting; do
            [[ -d "$HOME/.zsh/plugins/$_pd" ]] && {
              path+="$HOME/.zsh/plugins/$_pd"
              fpath+="$HOME/.zsh/plugins/$_pd"
            }
          done
          unset _pd
        '')

        # Source plugins (after oh-my-zsh)
        (lib.mkOrder 900 ''
          for _zp in \
            "zsh-powerlevel10k/powerlevel10k.zsh-theme" \
            "fzf-tab/fzf-tab.plugin.zsh" \
            "zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"; do
            [[ -f "$HOME/.zsh/plugins/$_zp" ]] && source "$HOME/.zsh/plugins/$_zp"
          done
          unset _zp
        '')

        # Portable fzf integration (replaces programs.fzf.enableZshIntegration)
        (lib.mkOrder 910 ''
          if [[ $options[zle] = on ]] && command -v fzf &>/dev/null; then
            source <(fzf --zsh)
          fi
        '')

        (commonShell.assembleInitExtra ./.zshrc)

        # Portable HISTFILE override (home-manager renders a hardcoded absolute path)
        (lib.mkOrder 1010 ''
          HISTFILE="$HOME/.local/share/zsh/history"
          mkdir -p "$(dirname "$HISTFILE")"
        '')

        # Portable nix-index, direnv, gpg-agent (replaces enableZshIntegration for each)
        (lib.mkOrder 1050 ''
          # nix-index command-not-found
          for _cnf in /etc/profiles/per-user/$USER/etc/profile.d/command-not-found.sh \
                      "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"; do
            if [[ -f "$_cnf" ]]; then source "$_cnf"; break; fi
          done
          unset _cnf

          # direnv
          if command -v direnv &>/dev/null; then
            eval "$(direnv hook zsh)"
          fi

          # gpg-agent
          if command -v gpg-connect-agent &>/dev/null; then
            export GPG_TTY=$TTY
            gpg-connect-agent --quiet updatestartuptty /bye > /dev/null 2>&1 || true
          fi
        '')

        # Syntax highlighting must be sourced last
        (lib.mkOrder 1200 ''
          [[ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
            source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        '')

        # Source local post-init config (not managed by Nix)
        (lib.mkOrder 1500 ''
          [[ -f "$HOME/.zsh/local.post.zsh" ]] && source "$HOME/.zsh/local.post.zsh"
        '')
      ];
      # profileExtra = builtins.readFile ./.zprofile;
      history = {
        size = 10000;
        # append = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        extended = true;
        path = "${config.xdg.dataHome}/zsh/history";
      };
      oh-my-zsh = {
        enable = true;
        # Others: direnv
        plugins = [
          "vi-mode"
          "aws"
          "docker"
          # "helm"
          # "kubectl"
          # "yarn"
          # "poetry"
          # "tailscale"
          "tmux"
        ];
        # theme = "robbyrussell";
        extraConfig = ''
          # Portable: fallback for oh-my-zsh if nix store path unavailable
          if [[ ! -d "''${ZSH:-}" ]]; then
            export ZSH="$HOME/.oh-my-zsh"
          fi

          # --------------------------------- FZF-Tab --------------------------------

          # https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#usage
          # FZF-Tab only affects ZSH completions

          # Use tmux popup for fzf-tab
          zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
          # set list-colors to enable filename colorizing
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
          # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
          zstyle ':completion:*' menu no
          # Hide . and .. from completions (globdots still shows other dotfiles)
          zstyle ':completion:*' special-dirs false
          # NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
          zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
        '';
      };
    };
  };
}
