{
  "[R]" = { "editor.wordWrap" = "on"; };
  "[css]" = {
    "editor.defaultFormatter" = "stylelint.vscode-stylelint";
    "editor.tabSize" = 2;
  };
  "[go]" = {
    "editor.codeActionsOnSave" = { "source.organizeImports" = "explicit"; };
    "editor.formatOnSave" = true;
  };
  "[html]" = { "editor.defaultFormatter" = "vscode.html-language-features"; };
  "[java]" = {
    "editor.defaultFormatter" = "redhat.java";
    "editor.tabSize" = 4;
  };
  "[javascript]" = { "editor.defaultFormatter" = "esbenp.prettier-vscode"; };
  "[json]" = { "editor.defaultFormatter" = "vscode.json-language-features"; };
  "[jsonc]" = { "editor.defaultFormatter" = "vscode.json-language-features"; };
  "[nix]" = { "editor.defaultFormatter" = "jnoortheen.nix-ide"; };
  "[python]" = {
    "editor.defaultFormatter" = "ms-python.black-formatter";
    "editor.formatOnType" = true;
  };
  "[r]" = { "editor.defaultFormatter" = "REditorSupport.r"; };
  "[scss]" = { "editor.defaultFormatter" = "esbenp.prettier-vscode"; };
  "[typescript]" = { "editor.defaultFormatter" = "dbaeumer.vscode-eslint"; };
  "[typescriptreact]" = {
    "editor.defaultFormatter" = "dbaeumer.vscode-eslint";
  };
  "[yaml]" = { "editor.defaultFormatter" = "redhat.vscode-yaml"; };
  "auto-open-css-modules.manualMode" = true;
  "auto-open-css-modules.openAsPreview" = false;
  "cmake.configureOnOpen" = false;
  "color-highlight.languages" = [ "!typescriptreact" "*" ];
  "css.validate" = false;
  "cursor.chat.premiumChatAutoScrollWhenAtBottom" = true;
  "debug.javascript.autoAttachFilter" = "disabled";
  "diffEditor.codeLens" = true;
  "diffEditor.useInlineViewWhenSpaceIsLimited" = false;
  "editor.accessibilitySupport" = "off";
  "editor.cursorStyle" = "line";
  "editor.inlineSuggest.enabled" = true;
  "editor.lineNumbers" = "on";
  "editor.minimap.enabled" = false;
  "editor.multiCursorModifier" = "ctrlCmd";
  "editor.suggestSelection" = "first";
  "editor.tabSize" = 4;
  "editor.wordSeparators" = ''/\()"':,.;<>~!@#$%^&*|+=[]{}`?-'';
  "emmet.includeLanguages" = { django-html = "html"; };
  "eslint.format.enable" = true;
  "eslint.workingDirectories" = [{ mode = "auto"; }];
  "extensions.experimental.affinity" = { "vscodevim.vim" = 1; };
  "files.associations" = {
    "**/requirements{/**,*}.{txt,in}" = "pip-requirements";
    "**/templates/*.html" = "django-html";
    "**/templates/*.txt" = "django-txt";
    "*.html" = "html";
    "*.module.css" = "scss";
    "*.tsx" = "typescriptreact";
  };
  "git.autorefresh" = false;
  "git.openRepositoryInParentFolders" = "always";
  "github.copilot.editor.enableAutoCompletions" = true;
  "github.copilot.enable" = {
    css = true;
    dockerfile = true;
    go = true;
    java = true;
    javascript = true;
    javascriptreact = true;
    python = true;
    r = true;
    ruby = true;
    rust = true;
    scss = true;
    typescript = true;
    typescriptreact = true;
    yaml = true;
  };
  "gitlens.cloudPatches.enabled" = false;
  "gitlens.graph.sidebar.enabled" = false;
  "gitlens.views.commitDetails.files.layout" = "tree";
  "gitlens.views.scm.grouped.views" = {
    branches = true;
    commits = true;
    contributors = true;
    launchpad = true;
    remotes = true;
    repositories = false;
    searchAndCompare = false;
    stashes = true;
    tags = true;
    worktrees = true;
  };
  "go.buildOnSave" = "off";
  "go.useLanguageServer" = true;
  "graphql-config.load.rootDir" = "./web";
  "gruvboxMaterial.darkContrast" = "soft";
  "gruvboxMaterial.darkPalette" = "material";
  "gruvboxMaterial.lightContrast" = "hard";
  "gruvboxMaterial.lightPalette" = "material";
  "java.configuration.checkProjectSettingsExclusions" = false;
  "java.help.firstView" = "gettingStarted";
  "java.project.importOnFirstTimeStartup" = "automatic";
  "java.refactor.renameFromFileExplorer" = "autoApply";
  "javascript.updateImportsOnFileMove.enabled" = "always";
  "keyboard.dispatch" = "keyCode";
  launch = {
    compounds = [ ];
    configurations = [
      {
        console = "integratedTerminal";
        name = "Node: Debug";
        profileStartup = true;
        request = "launch";
        skipFiles = [ "<node_internals>/**" ];
        trace = true;
        type = "node";
      }
      {
        name = "Browser: Chrome";
        request = "launch";
        skipFiles =
          [ "\${workspaceFolder}/node_modules/**" "<node_internals>/**" ];
        smartStep = true;
        type = "chrome";
        url = "http://localhost:3000";
        userDataDir = "\${userHome}/.vscode/chrome";
        webRoot = "\${workspaceRoot}/src";
      }
      {
        console = "integratedTerminal";
        justMyCode = true;
        name = "Python: Debug Current File";
        program = "\${file}";
        purpose = [ "debug-test" ];
        request = "launch";
        type = "debugpy";
      }
      {
        args = "\${input:args}";
        console = "integratedTerminal";
        justMyCode = true;
        name = "Python: Debug Current File With Args";
        program = "\${file}";
        purpose = [ "debug-test" ];
        request = "launch";
        type = "debugpy";
      }
      {
        args = "\${input:args}";
        console = "integratedTerminal";
        justMyCode = true;
        module = "\${input:module}";
        name = "Python: Debug Module";
        purpose = [ "debug-test" ];
        request = "launch";
        type = "debugpy";
      }
      {
        args = "\${input:args}";
        console = "integratedTerminal";
        justMyCode = true;
        name = "Python: Debug With File";
        program = "\${input:pickFileRemember}";
        purpose = [ "debug-test" ];
        request = "launch";
        type = "debugpy";
      }
      {
        args = "\${input:args}";
        console = "integratedTerminal";
        justMyCode = true;
        module = "poethepoet";
        name = "Python: Poe";
        purpose = [ "debug-test" ];
        request = "launch";
        type = "debugpy";
      }
      {
        connect = {
          host = "localhost";
          port = 5678;
        };
        name = "Python: Debug Attach";
        request = "attach";
        type = "debugpy";
      }
      {
        name = "Python: Debug Attach Process";
        processId = "\${command:pickProcess}";
        request = "attach";
        type = "debugpy";
      }
    ];
    inputs = [
      {
        args = {
          description = "Module to run";
          key = "module";
        };
        command = "extension.commandvariable.promptStringRemember";
        id = "module";
        type = "command";
      }
      {
        args = {
          description = "Args to run with";
          key = "args";
        };
        command = "extension.commandvariable.promptStringRemember";
        id = "args";
        type = "command";
      }
      {
        args = {
          default = null;
          description = "Which file?";
          options = [
            [ "Previous" "\${remember:pickedFile}" ]
            [ "Pick directory" "\${pickFile:pickedFile}" ]
          ];
          pickFile = {
            pickedFile = {
              description = "Select file:";
              exclude = "**/{node_modules,.venv}/**";
              keyRemember = "pickedFile";
              showDirs = false;
            };
          };
        };
        command = "extension.commandvariable.pickStringRemember";
        id = "pickFileRemember";
        type = "command";
      }
    ];
    version = "0.2.0";
  };
  "leetcode.defaultLanguage" = "python3";
  "leetcode.filePath" = {
    default = {
      filename = "test_\${id}_\${kebab-case-name}.\${ext}";
      folder = "/Users/mmaurer7/code/problems/problems";
    };
  };
  "leetcode.hint.commandShortcut" = false;
  "leetcode.hint.configWebviewMarkdown" = false;
  "leetcode.nodePath" =
    "/nix/store/ridvrr7dsnxpvh3f1sr41xiwvwk1nnkg-nodejs-20.12.2/bin/node";
  "leetcode.workspaceFolder" = "/Users/mmaurer7/code/problems/problems";
  "mypy.enabled" = false;
  "nix.enableLanguageServer" = true;
  "nix.formatterPath" = "nixpkgs-fmt";
  "nix.serverPath" = "nil";
  "nix.serverSettings" = {
    nil = {
      diagnostics = { ignored = [ "unused_binding" "unused_with" ]; };
      formatting = { command = [ "nixpkgs-fmt" ]; };
    };
  };
  "nixEnvSelector.args" = "--command 'zsh'";
  "nixEnvSelector.nixShellPath" = "nix develop";
  "npm.runInTerminal" = false;
  "python.testing.pytestEnabled" = true;
  "redhat.telemetry.enabled" = false;
  "remote.SSH.enableX11Forwarding" = false;
  "remote.WSL.fileWatcher.polling" = true;
  "remote.extensionKind" = { "vscode.typescript-language-features" = "ui"; };
  "scss.validate" = false;
  "search.exclude" = { "/tmp/**" = true; };
  "search.followSymlinks" = false;
  "settingsSync.keybindingsPerPlatform" = false;
  "sonarlint.analyzerProperties" = { };
  "sonarlint.rules" = {
    "java:S110" = { level = "off"; };
    "java:S1118" = { level = "off"; };
    "java:S117" = { level = "off"; };
    "java:S1186" = { level = "off"; };
    "java:S1192" = { level = "off"; };
    "java:S125" = { level = "off"; };
    "java:S1948" = { level = "off"; };
    "java:S2119" = { level = "off"; };
    "java:S2975" = { level = "off"; };
    "java:S3457" = { level = "off"; };
    "java:S3776" = { level = "off"; };
    "javascript:S3923" = { level = "off"; };
    "python:S1192" = { level = "off"; };
    "python:S2208" = { level = "off"; };
    "python:S3776" = { level = "off"; };
  };
  "sonarlint.testFilePattern" = "**/*.js";
  "stylelint.enable" = true;
  "svg.preview.mode" = "svg";
  "terminal.integrated.allowChords" = false;
  "terminal.integrated.altClickMovesCursor" = false;
  "terminal.integrated.defaultLocation" = "view";
  "terminal.integrated.defaultProfile.osx" = "tmux-pwd";
  "terminal.integrated.fontFamily" = "'MesloLGS NF'";
  "terminal.integrated.macOptionIsMeta" = true;
  "terminal.integrated.minimumContrastRatio" = 4;
  "terminal.integrated.profiles.linux" = {
    tmux-pwd = {
      args = [ "-l" "-i" "-c" "tmux_pwd \${workspaceFolder}" ];
      path = "zsh";
    };
  };
  "terminal.integrated.profiles.osx" = {
    tmux-pwd = {
      args = [ "-l" "-i" "-c" "tmux_pwd \${workspaceFolder}" ];
      path = "zsh";
    };
    zsh-login = {
      args = [ "-l" ];
      path = "zsh";
    };
  };
  "terminal.integrated.scrollback" = 10000;
  "terminal.integrated.showExitAlert" = true;
  "terminal.integrated.tabs.enabled" = false;
  "testing.openTesting" = "neverOpen";
  "typescript.updateImportsOnFileMove.enabled" = "always";
  "vim.insertModeKeyBindings" = [ ];
  "vim.leader" = "<space>";
  "vim.normalModeKeyBindingsNonRecursive" = [
    {
      before = [ "<leader>" "d" ];
      commands = [ "editor.action.showDefinitionPreviewHover" ];
    }
    {
      before = [ "<leader>" ";" ];
      commands = [ "workbench.action.quickSwitchWindow" ];
    }
    {
      before = [ "<leader>" "p" ];
      commands = [ "workbench.action.showCommands" ];
    }
    {
      before = [ "<leader>" "i" ];
      commands = [ "workbench.action.showAllSymbols" ];
    }
    {
      before = [ "<leader>" "o" ];
      commands = [ "workbench.action.quickOpen" ];
    }
    {
      before = [ "<leader>" "w" ];
      commands = [ "workbench.action.closeActiveEditor" ];
    }
    {
      before = [ "<leader>" "f" ];
      commands = [ "editor.action.formatDocument" ];
    }
    {
      before = [ "<leader>" "c" ];
      commands = [ "workbench.files.action.collapseExplorerFolders" ];
    }
    {
      before = [ "<leader>" "r" ];
      commands = [ "editor.action.rename" ];
    }
    {
      before = [ "<leader>" "e" "r" ];
      commands = [ "editor.action.startFindReplaceAction" ];
    }
    {
      before = [ "<leader>" "e" "n" ];
      commands = [ "editor.action.rename" ];
    }
    {
      before = [ "<leader>" "A" ];
      commands = [ "composer.createNew" ];
    }
    {
      before = [ "<leader>" "a" ];
      commands = [ "aipopup.action.modal.generate" ];
    }
    {
      before = [ "<leader>" "g" "s" ];
      commands = [ "gitlens.copyShaToClipboard" ];
    }
    {
      before = [ "<leader>" "g" "b" "h" ];
      commands = [ "gitlens.diffLineWithWorking" ];
    }
    {
      before = [ "<leader>" "g" "b" "b" ];
      commands = [ "gitlens.diffLineWithPrevious" ];
    }
    {
      before = [ "<leader>" "g" "g" ];
      commands = [ "gitlens.diffLineWithPrevious" ];
    }
    {
      before = [ "<leader>" "g" "h" ];
      commands = [ "gitlens.diffWithPreviousInDiffRight" ];
    }
    {
      before = [ "<leader>" "g" "l" ];
      commands = [ "gitlens.diffWithNextInDiffRight" ];
    }
    {
      before = [ "<leader>" "b" "r" ];
      commands = [ "workbench.action.debug.restart" ];
    }
    {
      before = [ "<leader>" "b" "x" ];
      commands = [ "workbench.debug.viewlet.action.removeAllBreakpoints" ];
    }
    {
      before = [ "<leader>" "b" "d" ];
      commands = [ "workbench.debug.action.focusRepl" ];
    }
    {
      before = [ "<leader>" "b" "w" ];
      commands = [ "editor.debug.action.selectionToWatch" ];
    }
    {
      before = [ "<leader>" "b" "s" ];
      commands = [ "workbench.action.debug.start" ];
    }
    {
      before = [ "<leader>" "b" "S" ];
      commands = [ "workbench.action.debug.selectandstart" ];
    }
    {
      before = [ "<leader>" "b" "f" ];
      commands = [ "workbench.action.debug.selectDebugSession" ];
    }
    {
      before = [ "<leader>" "b" "c" ];
      commands = [ "editor.debug.action.conditionalBreakpoint" ];
    }
    {
      before = [ "<leader>" "b" "b" ];
      commands = [ "editor.debug.action.toggleBreakpoint" ];
    }
    {
      before = [ "<leader>" "b" "j" ];
      commands = [ "debug.jumpToCursor" ];
    }
    {
      before = [ "H" ];
      commands = [ "workbench.action.previousEditor" ];
    }
    {
      before = [ "L" ];
      commands = [ "workbench.action.nextEditor" ];
    }
    {
      before = [ "<leader>" "h" "h" ];
      commands = [ "workbench.action.openPreviousRecentlyUsedEditorInGroup" ];
    }
    {
      before = [ "<leader>" "l" "l" ];
      commands = [ "workbench.action.openNextRecentlyUsedEditorInGroup" ];
    }
    {
      before = [ "J" ];
      commands = [ "editor.gotoNextFold" ];
    }
    {
      before = [ "K" ];
      commands = [ "editor.gotoPreviousFold" ];
    }
    {
      before = [ "<leader>" "j" "j" ];
      commands = [ "workbench.action.navigateBack" ];
    }
    {
      before = [ "<leader>" "k" "k" ];
      commands = [ "workbench.action.navigateForward" ];
    }
    {
      before = [ "<leader>" "j" "e" ];
      commands = [ "workbench.action.navigateBackInEditLocations" ];
    }
    {
      before = [ "<leader>" "k" "e" ];
      commands = [ "workbench.action.navigateForwardInEditLocations" ];
    }
    {
      before = [ "<leader>" "j" "d" ];
      commands = [ "editor.action.marker.next" ];
    }
    {
      before = [ "<leader>" "k" "d" ];
      commands = [ "editor.action.marker.prev" ];
    }
    {
      before = [ "<leader>" "j" "g" ];
      commands = [ "workbench.action.editor.nextChange" ];
    }
    {
      before = [ "<leader>" "k" "g" ];
      commands = [ "workbench.action.editor.previousChange" ];
    }
  ];
  "vim.statusBarColorControl" = false;
  "vim.useSystemClipboard" = true;
  "vim.visualModeKeyBindingsNonRecursive" = [
    {
      before = [ "<leader>" "p" ];
      commands = [ "workbench.action.showCommands" ];
    }
    {
      before = [ "<leader>" "a" ];
      commands = [ "aipopup.action.modal.generate" ];
    }
    {
      before = [ "<leader>" "s" ];
      commands = [ "editor.action.triggerSuggest" ];
    }
    {
      after = [ "}" ];
      before = [ "J" ];
    }
    {
      after = [ "{" ];
      before = [ "K" ];
    }
  ];
  "vsintellicode.modify.editor.suggestSelection" =
    "automaticallyOverrodeDefaultValue";
  "window.customMenuBarAltFocus" = false;
  "window.menuBarVisibility" = "hidden";
  "window.zoomLevel" = 1;
  "workbench.activityBar.location" = "hidden";
  "workbench.colorTheme" = "Gruvbox Material Light";
  "workbench.editor.autoLockGroups" = {
    default = false;
    terminalEditor = true;
    "workbench.editor.chatSession" = true;
  };
  "workbench.editorAssociations" = {
    "*.ico" = "luna.editor";
    "*.jpg" = "luna.editor";
    "*.png" = "luna.editor";
  };
  "workbench.panel.defaultLocation" = "right";
  "yaml.format.enable" = true;
}
