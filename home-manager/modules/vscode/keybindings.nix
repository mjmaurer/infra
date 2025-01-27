[
  {
    command = "workbench.action.compareEditor.nextChange";
    key = "down";
    when =
      "textCompareEditorActive && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.compareEditor.previousChange";
    key = "up";
    when =
      "textCompareEditorActive && !listHasSelectionOrFocus && !suggestWidgetVisible";
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
    command = "workbench.action.debug.start";
    key = "alt+s";
  }
  {
    command = "editor.debug.action.selectionToWatch";
    key = "alt+shift+s";
  }
  {
    command = "workbench.action.debug.stepOver";
    key = "down";
    when =
      "inDebugMode && editorTextFocus && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.debug.stepInto";
    key = "right";
    when =
      "inDebugMode && editorTextFocus && !listHasSelectionOrFocus && !suggestWidgetVisible";
  }
  {
    command = "workbench.action.debug.stepOut";
    key = "left";
    when =
      "inDebugMode && editorTextFocus && !listHasSelectionOrFocus && !suggestWidgetVisible";
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
    when =
      "editorHasCompletionItemProvider && editorTextFocus && !editorReadonly";
  }
  {
    command = "workbench.action.increaseViewSize";
    key = "alt+.";
  }
  {
    command = "workbench.action.decreaseViewSize";
    key = "alt+,";
  }
  {
    args = {
      commands = [
        "workbench.action.closeSidebar"
        "workbench.action.closePanel"
        "aichat.close-sidebar"
      ];
    };
    command = "runCommands";
    key = "alt+escape";
  }
  {
    command = "workbench.action.toggleMaximizeEditorGroup";
    key = "alt+shift+o";
  }
  {
    args = {
      commands = [
        "workbench.action.closeSidebar"
        "workbench.action.closePanel"
        "aichat.newchataction"
        "aichat.insertselectionintochat"
      ];
    };
    command = "runCommands";
    key = "alt+o";
    when = "editorFocus && editorHasSelection";
  }
  {
    args = {
      commands = [
        "workbench.action.closeSidebar"
        "workbench.action.closePanel"
        "aichat.newfollowupaction"
      ];
    };
    command = "runCommands";
    key = "alt+o";
    when = "editorFocus && !editorHasSelection";
  }
  {
    command = "workbench.action.focusFirstEditorGroup";
    key = "alt+o";
    when = "!editorFocus";
  }
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
    command = "workbench.action.toggleMaximizedPanel";
    key = "alt+shift+t";
  }
  {
    args = {
      commands = [
        "aichat.close-sidebar"
        "workbench.action.closeSidebar"
        "terminal.focus"
      ];
    };
    command = "runCommands";
    key = "alt+t";
    when = "!terminalFocus";
  }
  {
    command = "workbench.action.focusActiveEditorGroup";
    key = "alt+t";
    when = "terminalFocus";
  }
  {
    command = "terminal.focus";
    key = "alt+t";
    when = "!terminalFocus && view.terminal.visible";
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
