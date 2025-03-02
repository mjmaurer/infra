# See https://go.microsoft.com/fwlink/?LinkId=733558
# for the documentation about the tasks.json format
let
  defaultTerminalTaskConfig = {
    type = "shell";
    options = {
      env = {
        WORKSPACE = "\${workspaceFolderBasename}";
      };
      shell = {
        executable = "zsh";
        args = [ "-c" ];
      };
    };
    isBackground = true;
    presentation = {
      echo = true;
      reveal = "always";
      focus = false;
      panel = "dedicated";
      showReuseMessage = false;
      clear = false;
      close = true;
    };
    runOptions = {
      runOn = "folderOpen";
    };
    problemMatcher = [ ];
  };
in
{
  version = "2.0.0";
  tasks = [
    (
      defaultTerminalTaskConfig
      // {
        label = "Aider";
        command = "tmuxp";
        args = [
          "load"
          "--yes"
          "vscode-aider"
        ];
      }
    )
    (
      defaultTerminalTaskConfig
      // {
        label = "Main";
        command = "tmuxp";
        args = [
          "load"
          "--yes"
          "vscode-main"
        ];
      }
    )
    # {
    #     "label": "Aider",
    #     "type": "shell",
    #     "command": "tmux_switch_by_name infra infra-aider",
    #     "options": {
    #         "shell": {
    #             "executable": "/bin/zsh",
    #             "args": [
    #                 "-c"
    #             ]
    #         }
    #     },
    #     "isBackground": false,
    #     "presentation": {
    #         "echo": true,
    #         "reveal": "silent",
    #         "focus": false,
    #         "panel": "dedicated",
    #         "showReuseMessage": false,
    #         "clear": false,
    #         "close": true
    #     },
    #     "problemMatcher": []
    # },
    # {
    #     "label": "Aider Copy",
    #     "command": "${command:workbench.action.terminal.paste}",
    #     "dependsOn": [
    #         "Aider"
    #     ],
    #     "dependsOrder": "sequence",
    #     "problemMatcher": []
    # }
  ];
}
