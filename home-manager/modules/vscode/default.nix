# Includes SSH, GPG, and Yubikey
{ osConfig ? null, lib, config, isDarwin, pkgs, inputs, system, ... }:
let
  cfg = config.modules.vscode;
  isNixOS = !isDarwin;
  package = if isNixOS then pkgs.vscode.fhs else pkgs.vscode;
  vsxmkt = inputs.nix-vscode-extensions.extensions.${system};
  nix4vscode = (import ./extensions.nix) { inherit pkgs lib; };
  vscode-marketplace =
    (vsxmkt.forVSCodeVersion package.version).vscode-marketplace;
in {
  options.modules.vscode = { };

  config = lib.mkMerge [{
    modules.nix = { unfreePackages = [ "vscode" ]; };

    # NOTE: Home-manager vscode doesn't support FHS launch environment.
    # Might be useful if extensions depend on some system libraries.

    programs.vscode = {
      enable = true;
      # Darwin doesn't support FHS launch environment
      package = package;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      # Might cause problems:
      mutableExtensionsDir = true;
      userSettings = import ./settings.nix;
      userTasks = import ./tasks.nix;
      keybindings = import ./keybindings.nix { editor = "vscode"; };
      extensions = (with vscode-marketplace; [
        # Extensions kept up to date via:
        # https://github.com/nix-community/nix-vscode-extensions
        # Get list of extensions: https://github.com/nix-community/nix-vscode-extensions?tab=readme-ov-file#get-extensions-with-flakes

        nix4vscode.github.vscode-pull-request-github
        nix4vscode.github.copilot-chat

        vscodevim.vim
        github.copilot
        visualstudioexptteam.intellicode-api-usage-examples
        visualstudioexptteam.vscodeintellicode
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-wsl
        ms-vscode.remote-explorer
        rioj7.command-variable
        sleistner.vscode-fileutils

        andrsdc.base16-themes
        sainnhe.gruvbox-material
        stackbreak.comment-divider
        takumii.tabspace
        naumovs.color-highlight

        jnoortheen.nix-ide
        mkhl.direnv
        hashicorp.terraform
        eamodio.gitlens
        github.vscode-github-actions
        ms-azuretools.vscode-docker
        # arrterian.nix-env-selector

        # bierner.markdown-checkbox
        dotjoshjohnson.xml
        grapecity.gc-excelviewer
        jock.svg
        # "42crunch".vscode-openapi
        tamasfe.even-better-toml
        redhat.vscode-yaml
        # tyriar.luna-paint Issue with SHA mismatch
        mrorz.language-gettext

        # TODO anysphere.pyright # cursor

        ms-python.black-formatter
        ms-python.debugpy
        ms-python.isort
        ms-python.pylint
        ms-python.python
        ms-python.vscode-pylance
        batisteo.vscode-django
        matangover.mypy
        mikoz.black-py
        njpwerner.autodocstring
        # ms-toolsai.jupyter
        # ms-toolsai.jupyter-keymap
        # ms-toolsai.jupyter-renderers
        # ms-toolsai.vscode-jupyter-cell-tags
        # ms-toolsai.vscode-jupyter-slideshow

        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        firsttris.vscode-jest-runner
        stylelint.vscode-stylelint
        raymondcamden.htmlescape-vscode-extension
        # svelte.svelte-vscode
        # graphql.vscode-graphql
        # graphql.vscode-graphql-execution
        # graphql.vscode-graphql-syntax

        slevesque.shader

        jakebecker.elixir-ls

        # josetr.cmake-language-support-vscode
        # ms-vscode.cmake-tools
        # ms-vscode.cpptools
        # ms-dotnettools.csharp
        # ms-dotnettools.vscode-dotnet-runtime
        # twxs.cmake

        rdebugger.r-debugger
        reditorsupport.r

        redhat.java
        redhat.vscode-commons
        # vscjava.vscode-gradle
        vscjava.vscode-java-debug
        vscjava.vscode-java-dependency
        vscjava.vscode-java-pack
        vscjava.vscode-java-test
        vscjava.vscode-maven
        sohibe.java-generate-setters-getters

      ]) ++ (pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # Manually added extensions

        # {
        #   name = "";
        #   publisher = "";
        #   version = "0.3.1";
        #   sha256 = "sha256-";
        # }
      ]) ++ (with pkgs.vscode-extensions;
        [
          # Extensions from nixpkgs (tend to be outdated)
        ]);
      languageSnippets = { };
      globalSnippets = { };
    };
  }];
}
