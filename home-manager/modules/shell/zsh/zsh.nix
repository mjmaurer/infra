{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.zsh;
  commonShell = config.modules.commonShell;
in
{
  options.modules.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf cfg.enable {

    home.file = {
      ".p10k.zsh" = {
        source = ./p10k.zsh;
      };
    };

    programs.zsh = {
      enable = true;
      package = pkgs.zsh;

      # This actually doesn't do anything since Nix gives
      # oh-my-zsh responsibility for calling compinit
      enableCompletion = true;
      autosuggestion.enable = false;
      syntaxHighlighting.enable = true;

      dirHashes = commonShell.dirHashes // { };
      sessionVariables = commonShell.sessionVariables // { };
      shellAliases = commonShell.shellAliases // {
        "hig" = "history 0 | grep";
        "hmswitch" = ''
          hmswitchnoload;
          source ~/.zshrc
        '';
      };
      shellGlobalAliases = {
        hp = "HEAD~1";
        hpp = "HEAD~2";
        hppp = "HEAD~3";
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
      initExtraFirst = ''
        # Show hidden files without needing to type .
        setopt globdots

        VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
        VI_MODE_SET_CURSOR=true
        ZSH_AUTOSUGGEST_STRATEGY=(history)
        # https://github.com/NixOS/nix/issues/1577
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        else
          echo "WARNING: nix-daemon.sh not found"
        fi

        source ${./aichat.zsh}
        bindkey '^G^G' _aichat_zsh

        # Load theme
        # fpath+=(${pkgs.zsh-powerlevel10k}/share/zsh/site-functions)
        # autoload -U promptinit; promptinit
        # prompt powerlevel10k
      '';
      initExtra = commonShell.assembleInitExtra ./.zshrc;
      # profileExtra = builtins.readFile ./.zprofile;
      history = {
        size = 10000;
        # append = true;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        extended = true;
        path = "${config.xdg.dataHome}/zsh/history";
      };
      plugins = [
        # {
        #   name = "powerlevel10k-config";
        #   src = ./p10k.zsh;
        #   file = "p10k.zsh";
        # }
        {
          name = "zsh-powerlevel10k";
          src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
          file = "powerlevel10k.zsh-theme";
        }
        # FZF-tab needs to come before autosuggestions / syntax highlighting
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "v1.1.2";
            sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
          };
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "v0.7.0";
            sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
          };
        }
      ];
      oh-my-zsh = {
        enable = true;
        # Others: direnv
        plugins = [ "vi-mode" "thefuck" "aws" "docker" "helm" "kubectl" "yarn" "poetry" "tailscale" "tmux" ];
        # theme = "robbyrussell";
        extraConfig = ''
          # --------------------------------- FZF-Tab -------------------------------- 

          # https://github.com/Aloxaf/fzf-tab?tab=readme-ov-file#usage
          # FZF-Tab only affects ZSH completions

          # Use tmux popup for fzf-tab
          zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
          # set list-colors to enable filename colorizing
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
          # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
          zstyle ':completion:*' menu no
          # NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
          zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
        '';
      };
    };
  };
}
