{ editor }:
# https://code.visualstudio.com/api/references/when-clause-contexts
# To inspect
# 1. Help -> Toggle Developer Tools (Opens Console) 
# 2. Run `Developer: Inspect Context Keys` 
let
  editorConf = {
    cursor = {
      closeChat = [ "aichat.close-sidebar" ];
      openWithSelection = [
        "aichat.newchataction"
        "aichat.insertselectionintochat"
      ];
      openExisting = [ "aichat.newfollowupaction" ];
    };
    vscode = {
      closeChat = [ "workbench.action.closeAuxiliaryBar" ];
      openWithSelection = [ "workbench.action.chat.newChat" ];
      openExisting = [ "workbench.panel.chat.view.copilot.focus" ];
    };
  };
  cfg = editorConf.${editor};
in
[
  {
    command = "workbench.action.compareEditor.nextChange";
    key = "down";
    when = "textCompareEditorActive && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.compareEditor.previousChange";
    key = "up";
    when = "textCompareEditorActive && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    # Doesn't work:
    # https://github.com/microsoft/vscode/issues/225879
    command = "diffEditor.revert";
    key = "right";
    when = "textCompareEditorActive && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    # This is to unset the comment divider command
    command = "";
    key = "alt+x";
    when = "!inDebugMode";
  }
  {
    command = "testing.debugAtCursor";
    key = "alt+e";
  }
  {
    command = "testing.debugCurrentFile";
    key = "alt+shift+e";
  }
  {
    command = "extension.debugJest";
    key = "alt+e";
    when = "resourceFilename =~ /.*test\\.(js|jsx|ts|tsx)$/";
  }
  {
    command = "extension.watchJest";
    key = "alt+shift+e";
    when = "resourceFilename =~ /.*test\\.(js|jsx|ts|tsx)$/";
  }
  # Now used for tmux:
  # {
  #   command = "workbench.action.debug.start";
  #   key = "alt+s";
  # }
  # {
  #   command = "editor.debug.action.selectionToWatch";
  #   key = "alt+shift+s";
  # }
  {
    command = "workbench.action.debug.stepOver";
    key = "down";
    when = "inDebugMode && editorTextFocus && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.debug.stepInto";
    key = "right";
    when = "inDebugMode && editorTextFocus && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.debug.stepOut";
    key = "left";
    when = "inDebugMode && editorTextFocus && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.debug.restart";
    key = "alt+r";
    when = "inDebugMode";
  }
  {
    command = "testing.debugLastRun";
    key = "alt+r";
    when = "!inDebugMode";
  }
  {
    command = "workbench.action.debug.stop";
    key = "alt+q";
    when = "inDebugMode";
  }
  {
    command = "workbench.action.debug.disconnect";
    key = "alt+x";
    when = "inDebugMode";
  }
  {
    command = "workbench.action.debug.continue";
    key = "alt+c";
    when = "inDebugMode";
  }
  {
    command = "editor.action.triggerSuggest";
    key = "alt+d";
    when = "editorHasCompletionItemProvider && editorTextFocus && !editorReadonly";
  }
  {
    command = "workbench.action.increaseViewSize";
    key = "alt+.";
  }
  {
    command = "workbench.action.decreaseViewSize";
    key = "alt+,";
  }
  # Hide / Maximize
  {
    args = {
      commands = [
        "workbench.action.closeSidebar"
        "workbench.action.closePanel"
      ] ++ cfg.closeChat;
    };
    command = "runCommands";
    key = "alt+escape";
  }
  {
    command = "workbench.action.togglePanel";
    key = "alt+shift+t";
  }
  # Chat / AI Misc
  {
    command = "inlineChat.acceptChanges";
    key = "alt+enter";
    when = "inlineChatFocused";
  }
  {
    command = "chatEditor.action.accept";
    key = "alt+enter";
    when = "chat.hasEditorModifications && editorFocus";
  }
  {
    command = "chatEditing.acceptAllFiles";
    key = "alt+enter";
    when = "hasUndecidedChatEditingResource && inChatInput && !chatSessionRequestInProgress && chatLocation == 'editing-session'";
  }
  # Chat open
  # {
  #   args = {
  #     commands = [ "workbench.action.closePanel" ] ++ cfg.openWithSelection;
  #   };
  #   command = "runCommands";
  #   key = "alt+a";
  #   when = "editorFocus && editorHasSelection";
  # }
  {
    args = {
      commands = [ "workbench.action.closePanel" ] ++ cfg.openExisting;
    };
    command = "runCommands";
    key = "alt+a";
    when = "editorFocus";
  }
  {
    command = "workbench.action.focusFirstEditorGroup";
    key = "alt+a";
    when = "!editorFocus";
  }
  {
    command = "workbench.panel.chatEditing";
    key = "alt+shift+a";
  }
  {
    command = "workbench.action.chat.newChat";
    key = "alt+n";
    when = "!editorFocus && !terminalFocus";
  }
  # Terminal (Main) focus
  {
    args = {
      commands = cfg.closeChat ++ [ "workbench.action.terminal.focusAtIndex2" ];
    };
    command = "runCommands";
    key = "alt+t";
    when = "!terminalFocus && !panelFocus";
  }
  {
    # Maintain open panel if not terminal
    command = "workbench.action.focusActiveEditorGroup";
    key = "alt+t";
    when = "!terminalFocus && panelFocus";
  }
  {
    command = "workbench.action.terminal.focusAtIndex2";
    key = "alt+t";
    when = "!terminalFocus && view.terminal.visible";
  }
  {
    command = "workbench.action.focusActiveEditorGroup";
    key = "alt+t";
    when = "terminalFocus";
  }
  # Terminal (Aider) focus
  {
    args = {
      commands =
        [ "editor.action.clipboardCopyAction" ]
        ++ cfg.closeChat
        ++ [ "workbench.action.terminal.focusAtIndex1" ];
    };
    command = "runCommands";
    key = "alt+o";
    when = "!terminalFocus";
  }
  {
    command = "workbench.action.terminal.focusAtIndex1";
    key = "alt+o";
    when = "!terminalFocus && view.terminal.visible";
  }
  {
    command = "runCommands";
    args = {
      commands = [
        "editor.action.clipboardCopyAction"
        "workbench.action.terminal.focusAtIndex1"
        "editor.action.clipboardPasteAction"
      ];
    };
    key = "alt+shift+o";
    when = "editorHasSelection && !terminalFocus && view.terminal.visible";
  }
  {
    command = "runCommands";
    args = {
      commands = [
        # { command = "copyRelativeFilePath"; }
        { command = "workbench.action.terminal.focusAtIndex1"; }
        {
          command = "workbench.action.terminal.sendSequence";
          args = {
            text = ''
              /reset
            '';
          };
        }
        # { command = "editor.action.clipboardPasteAction"; }
      ];
    };
    key = "alt+shift+o";
    when = "!editorHasSelection && view.terminal.visible";
  }
  {
    command = "workbench.action.focusActiveEditorGroup";
    key = "alt+o";
    when = "terminalFocus";
  }
  # Primary sidebar focus
  {
    command = "workbench.files.action.collapseExplorerFolders";
    key = "alt+shift+i";
  }
  {
    command = "workbench.action.toggleSidebarVisibility";
    key = "alt+i";
    when = "sideBarVisible";
  }
  {
    command = "workbench.action.focusSideBar";
    key = "alt+i";
    when = "!sideBarVisible";
  }
  {
    command = "-editor.action.inlineEdits.showNext";
    key = "alt+]";
    when = "inlineEditsVisible && !editorReadonly";
  }
  {
    command = "-editor.action.outdentLines";
    key = "cmd+[";
    when = "editorTextFocus && !editorReadonly";
  }
  {
    command = "-workbench.action.compareEditor.nextChange";
    key = "alt+f5";
    when = "textCompareEditorVisible";
  }
  {
    command = "editor.action.dirtydiff.next";
    key = "cmd+[";
  }
  {
    command = "-editor.action.dirtydiff.next";
    key = "alt+f3";
    when = "editorTextFocus && !textCompareEditorActive";
  }
]
