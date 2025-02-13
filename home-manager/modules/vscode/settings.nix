let
  vimNormalAndVisual = [
    {
      before = [ "<leader>" "p" ];
      commands = [ "workbench.action.showCommands" ];
    }
    {
      before = [ "<leader>" "a" "a" ];
      commands = [ "inlineChat.start" ];
    }
    # Prefix-------------------------- Editor Leader --------------------------
    {
      before = [ "<leader>" "e" "e" ];
      commands = [ "editor.action.addCommentLine" ];
    }
    {
      before = [ "<leader>" "e" "r" ];
      commands = [ "editor.action.startFindReplaceAction" ];
    }
    {
      before = [ "<leader>" "e" "n" ];
      commands = [ "editor.action.rename" ];
    }
    # Prefix-------------------------- Git Leader --------------------------
    {
      # git blame diff head (diff blame commit against head for file)
      # See what has changed since the commit
      before = [ "<leader>" "g" "c" ];
      commands = [ "gitlens.copyRemoteFileUrlToClipboard" ];
    }
    {
      before = [ "<leader>" "g" "r" ];
      commands = [ "git.revertSelectedRanges" ];
    }
  ];
in {
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
  "diffEditor.ignoreTrimWhitespace" = false;
  "direnv.restart.automatic" = true;
  "editor.accessibilitySupport" = "off";
  "editor.cursorStyle" = "line";
  # copilot suggest
  "editor.inlineSuggest.enabled" = true;
  "editor.inlineSuggest.showToolbar" = true;
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
  "git.autoRepositoryDetection" = true;
  # Don't offer to pull branch
  "githubPullRequests.pullBranch" = "never";
  "github.copilot.editor.enableAutoCompletions" = true;
  "github.copilot.chat.scopeSelection" = true;
  "github.copilot.chat.followUps" = "firstOnly";
  "github.copilot.chat.startDebugging.enabled" = true;
  "github.copilot.chat.terminalChatLocation" = "quickChat";
  "github.copilot.editor.enableCodeActions" = true;
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
  # "jest.enable": false,
  # "jest.debugMode": true,
  # "jest.runMode": "on-demand",
  # "jest.outputConfig": "terminal-based",
  # "jest.jestCommandLine": "npm test",
  # "jest.shell": {
  #     "path": "nix",
  #     "args": [
  #         "develop",
  #         "--command",
  #         "zsh"
  #     ]
  # }
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
      # Options: https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md
      {
        name = "Browser: Chrome";
        request = "launch";
        skipFiles =
          [ "\${workspaceFolder}/node_modules/**" "<node_internals>/**" ];
        smartStep = true;
        type = "chrome";
        url = "http://localhost:3000";
        # This will have to be setup after first use
        userDataDir = "\${userHome}/.vscode/chrome";
        webRoot = "\${workspaceRoot}/src";
      }
      {
        # Works for tests / files.
        # Tests might need pytest enabled

        # Right now, refresh is broken for integrated terminal.
        # It still works for console, but let's wait
        # https://github.com/microsoft/vscode-python-debugger/issues/338
        console = "integratedTerminal";
        justMyCode = true;
        name = "Python: Debug Current File";
        program = "\${file}";

        # This works for non-test files too for
        # some reason.
        purpose = [ "debug-test" ];
        request = "launch";
        # type "python" is deprecated but means the same
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

      # {
      #     "name": "Python: Poetry",
      #     "type": "debugpy",
      #     "request": "launch",
      #     "module": "poetry",
      #     "args": [
      #         "${input:command}"
      #     ],
      #     "purpose": [
      #         "debug-test"
      #     ],
      #     "console": "integratedTerminal",
      #  justMyCode = true
      # }
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
  "nix.formatterPath" = "nixfmt";
  "nix.serverPath" = "nil";
  "nix.serverSettings" = {
    nil = {
      diagnostics = { ignored = [ "unused_binding" "unused_with" ]; };
      formatting = { command = [ "nixfmt" ]; };
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
  "terminal.integrated.fontFamily" = "'MesloLGS NF'";
  "terminal.integrated.macOptionIsMeta" = true;
  "terminal.integrated.minimumContrastRatio" = 2;
  # These next two are an attempt to get a blank zsh shell from auto-opening (and instead depend on tmuxp tasks)
  "terminal.integrated.enablePersistentSessions" = false;
  "terminal.integrated.hideOnStartup" = "always";
  "terminal.integrated.profiles.linux" = {
    tmux-pwd = {
      args = [ "-l" "-c" "tmux_pwd \${@:1} \${workspaceFolder}" "_" ];
      path = "zsh";
    };
  };
  "terminal.integrated.defaultProfile.osx" = "tmux-pwd";
  "terminal.integrated.profiles.osx" = {
    tmux-pwd = {
      # This passes all arguments after underscore to tmux_pwd. Useful for treating tmux as a shell (becuase tmux_pwd accepts '-c' for commands)
      # Used to have -i here (but don't need it I think. was causing problems for automation profile usage)
      args = [ "-l" "-c" "tmux_pwd \${@:1} \${workspaceFolder}" "_" ];
      path = "zsh";
    };
    zsh-login = {
      args = [ "-l" ];
      path = "zsh";
    };
  };
  # "terminal.integrated.automationProfile.osx": {
  #     "path": "zsh",
  #     "args": [
  #         "-l",
  #     ]
  # },
  "terminal.integrated.scrollback" = 10000;
  "terminal.integrated.showExitAlert" = true;
  "terminal.integrated.tabs.enabled" = false;
  "testing.openTesting" = "neverOpen";
  "testing.automaticallyOpenTestResults" = "neverOpen";
  "typescript.updateImportsOnFileMove.enabled" = "always";
  "vim.insertModeKeyBindings" = [ ];
  "vim.leader" = "<space>";
  "vim.statusBarColorControl" = false;
  "vim.useSystemClipboard" = true;
  "vim.normalModeKeyBindingsNonRecursive" = vimNormalAndVisual ++ [
    # Prefix---------------------------- Editor Raw ---------------------------
    {
      before = [ "<leader>" "d" ];
      commands = [ "editor.action.showDefinitionPreviewHover" ];
    }
    {
      before = [ "<leader>" ";" ];
      commands = [ "workbench.action.quickSwitchWindow" ];
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
      before = [ "<leader>" "w" "w" ];
      commands = [ "workbench.action.closeActiveEditor" ];
    }
    {
      before = [ "<leader>" "w" "h" ];
      commands = [ "workbench.action.closeEditorsToTheLeft" ];
    }
    {
      before = [ "<leader>" "w" "l" ];
      commands = [ "workbench.action.closeEditorsToTheRight" ];
    }
    {
      before = [ "<leader>" "w" "o" ];
      commands = [ "workbench.action.closeOtherEditors" ];
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
    # Prefix------------------------- LLM / AI / Cursor -------------------------
    {
      before = [ "<leader>" "a" "f" ];
      commands = [ "github.copilot.edits.attachFile" ]; # "composer.createNew"
    }
    # Prefix---------------------------- Git -----------------------------
    {
      before = [ "<leader>" "g" "s" ];
      commands = [ "gitlens.copyShaToClipboard" ];
    }
    {
      # git blame diff head (diff blame commit against head for file)
      # See what has changed since the commit
      before = [ "<leader>" "g" "b" "h" ];
      commands = [ "gitlens.diffLineWithWorking" ];
    }
    {
      # Duplicated in case I forget
      before = [ "<leader>" "g" "g" ];
      commands = [ "gitlens.diffLineWithWorking" ];
    }
    {
      # git show blame commit
      before = [ "<leader>" "g" "b" "b" ];
      commands = [ "gitlens.diffLineWithPrevious" ];
    }
    {
      # Duplicated in case I forget
      before = [ "<leader>" "g" "d" ];
      commands = [ "gitlens.diffLineWithPrevious" ];
    }
    {
      # Revert current line change
      before = [ "<leader>" "g" "r" ];
      commands = [ "git.revertSelectRanges" ];
    }
    {
      # Prev: Diff current file with most recent previous version of it
      before = [ "<leader>" "g" "h" ];
      commands = [ "gitlens.diffWithPreviousInDiffRight" ];
    }
    {
      # Next: Diff current file with most recent version after it
      before = [ "<leader>" "g" "l" ];
      commands = [ "gitlens.diffWithNextInDiffRight" ];
    }
    # Prefix-------------------------- Debugging --------------------------
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
    # Prefix--------------------- Movement: Left / Right -----------------------
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
    # Prefix--------------------- Movement: Up / Down ------------------------
    {
      before = [ "J" ];
      commands = [ "editor.gotoNextFold" ];
    }
    {
      before = [ "K" ];
      commands = [ "editor.gotoPreviousFold" ];
    }
    {
      # Jumplist prev
      # "<C-o>"
      before = [ "<leader>" "j" "j" ];
      commands = [ "workbench.action.openPreviousRecentlyUsedEditor" ];
    }
    {
      before = [ "<leader>" "k" "k" ];
      commands = [ "workbench.action.openNextRecentlyUsedEditor" ];
    }
    # The navigation stack only affects certain navigations (like GoToDefinition)
    # I'll call this the "view" or "vim" stack
    # See https://github.com/microsoft/vscode/issues/142647
    {
      before = [ "<leader>" "j" "v" ];
      commands = [ "workbench.action.navigateBackInNavigationLocations" ];
    }
    {
      before = [ "<leader>" "k" "v" ];
      commands = [ "workbench.action.navigateForwardInNavigationLocations" ];
    }
    {
      before = [ "<leader>" "j" "f" ];
      commands = [ "workbench.action.navigateBack" ];
    }
    {
      before = [ "<leader>" "k" "f" ];
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
  "vim.visualModeKeyBindingsNonRecursive" = vimNormalAndVisual ++ [
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
  "workbench.activityBar.location" = "top";
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
