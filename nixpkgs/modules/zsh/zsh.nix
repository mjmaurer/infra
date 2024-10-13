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

      sessionVariables = commonShell.sessionVariables // { };
      shellAliases = commonShell.shellAliases // {
        "hig" = "history 0 | grep";
        "hmswitch" = ''
          hmswitchnoload;
          source ~/.zshrc
        '';
      };
      shellGlobalAliases = {
        G = "| grep";
      };

      defaultKeymap = "viins";
      dirHashes = {
        # cd ~code
        # "code" = "$HOME/code";
      };
      initExtraFirst = ''
        VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
        VI_MODE_SET_CURSOR=true
        ZSH_AUTOSUGGEST_STRATEGY=(history)
        # https://github.com/NixOS/nix/issues/1577
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        else
          echo "WARNING: nix-daemon.sh not found"
        fi

        # Load theme
        # fpath+=(${pkgs.zsh-powerlevel10k}/share/zsh/site-functions)
        # autoload -U promptinit; promptinit
        # prompt powerlevel10k
      '';
      initExtra = commonShell.initExtra + "\n" + commonShell.rc + "\n" + (builtins.readFile ./.zshrc);
      profileExtra = builtins.readFile ./.zprofile;
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
        plugins = [ "vi-mode" "thefuck" "aws" "docker" "helm" "kubectl" "yarn" "poetry" "tailscale" "terraform" "tmux" ];
        # theme = "robbyrussell";
        extraConfig = ''
          zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
        '';
      };
    };
  };
}
