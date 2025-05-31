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
  # Useful for when binding arrows (esp up / down arrows)
  arrowAvoidCond = "!listHasSelectionOrFocus && !suggestWidgetVisible && !inlineSuggestionVisible && !inlineEditsVisible";
  textEditor = "editorTextFocus";

  conditionInlineSuggestArrows = "inlineSuggestionVisible || inlineEditIsVisible";
  conditionDiffArrows = "textCompareEditorActive && ${textEditor} && ${arrowAvoidCond}";
  conditionDebugArrows = "inDebugMode && ${textEditor} && ${arrowAvoidCond}";
in
[
  # {
  #   key = "tab";
  #   command = "list.expand";
  #   when = "listFocus && treeElementCanExpand && !inputFocus && !treestickyScrollFocused || listFocus && treeElementHasChild && !inputFocus && !treestickyScrollFocused";
  # }
  {
    command = "editor.action.triggerSuggest";
    key = "alt+d";
    when = "editorHasCompletionItemProvider && editorTextFocus && !editorReadonly";
  }
  # ------------------------------- Diff Editor ------------------------------
  {
    command = "workbench.action.compareEditor.nextChange";
    key = "down";
    when = conditionDiffArrows;
  }
  {
    command = "workbench.action.compareEditor.previousChange";
    key = "up";
    when = conditionDiffArrows;
  }
  {
    # Doesn't work: https://github.com/microsoft/vscode/issues/225879
    command = "diffEditor.revert";
    key = "right";
    when = conditionDiffArrows;
  }
  # ---------------------------------- Debug ---------------------------------
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
  {
    command = "workbench.action.debug.stepOver";
    key = "down";
    when = conditionDebugArrows;
  }
  {
    command = "workbench.action.debug.stepInto";
    key = "right";
    when = conditionDebugArrows;
  }
  {
    command = "workbench.action.debug.stepOut";
    key = "left";
    when = conditionDebugArrows;
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
  # ------------------------------- Misc Layout ------------------------------
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
  # ----------------------------- Copilot Chat / AI -----------------------------
  {
    key = "right";
    command = "editor.action.inlineSuggest.commit";
    # Copied except removed "!suggestWidgetVisible"
    when = "inlineEditIsVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus || inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editorHoverFocused && !editorTabMovesFocus || inlineEditIsVisible && inlineSuggestionHasIndentationLessThanTabSize && inlineSuggestionVisible && !editorHoverFocused && !editorTabMovesFocus || inlineEditIsVisible && inlineSuggestionVisible && tabShouldAcceptInlineEdit && !editorHoverFocused && !editorTabMovesFocus";
  }
  {
    key = "shift+right";
    command = "editor.action.inlineSuggest.acceptNextWord";
    when = "inlineSuggestionVisible && ${textEditor}";
  }
  {
    key = "right";
    command = "editor.action.inlineSuggest.jump";
    # Copied except removed "!suggestWidgetVisible"
    when = "inlineEditIsVisible && tabShouldJumpToInlineEdit && !editorHoverFocused && !editorTabMovesFocus";
  }
  {
    command = "chatEditing.acceptAllFiles";
    key = "alt+enter";
    when = "inChat";
  }
  {
    command = "chatEditor.action.acceptHunk";
    key = "alt+enter";
    when = "editorFocus";
  }
  {
    command = "chatEditor.action.accept";
    key = "alt+shift+enter";
    when = "editorFocus";
  }
  {
    command = "inlineChat.acceptChanges";
    key = "alt+enter";
    when = "inlineChatHasProvider && inlineChatVisible";
  }
  {
    command = "chatEditor.action.toggleDiff";
    key = "alt+g";
    when = "editorFocus";
  }
  {
    command = "workbench.action.chat.newChat";
    key = "cmd+n";
    when = "inChat";
  }
  {
    command = "workbench.action.chat.history";
    key = "cmd+y";
    when = "inChat";
  }
  {
    command = "workbench.action.chat.openModelPicker";
    key = "cmd+t";
    when = "inChat || inlineChatFocused";
  }
  {
    command = "workbench.action.chat.toggleAgentMode";
    key = "cmd+m";
    when = "inChat || inlineChatFocused";
  }
  {
    command = "list.scrollDown";
    key = "pagedown";
    when = "inChat";
  }
  {
    command = "list.scrollUp";
    key = "pageup";
    when = "inChat";
  }
  {
    command = "workbench.action.chat.nextCodeBlock";
    key = "down";
    when = "inChat";
  }
  {
    command = "workbench.action.chat.previousCodeBlock";
    key = "up";
    when = "inChat";
  }
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
  # -------------------------- Terminal (Main) focus -------------------------
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
  # ------------------------- Terminal (Aider) focus -------------------------
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
  # -------------------------- Primary sidebar focus -------------------------
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
  # --------------------------------- Unbind ---------------------------------
  # Vim Ext Fixes (https://github.com/VSCodeVim/Vim/issues/9459#issuecomment-2648156285)
  {
    key = "escape";
    command = "-extension.vim_escape";
    when = "vim.active && vim.mode == 'Normal'";
  }
  {
    # Remove VSCodeVim's handling of tab to enable default handling of tab
    # e.g. for inline suggestions.
    key = "tab";
    command = "-extension.vim_tab";
  }
  {
    # Remove tab to complete intellisense
    key = "tab";
    command = "-acceptSelectedSuggestion";
  }
  {
    key = "tab";
    command = "-editor.action.inlineSuggest.jump";
  }
  {
    key = "tab";
    command = "-editor.action.inlineSuggest.commit";
  }
  {
    # Not sure what this one does
    key = "tab";
    command = "-insertNextSuggestion";
  }
  {
    key = "right";
    command = "-cursorRight";
    when = "!${textEditor}";
  }
  # {
  #   key = "left";
  #   command = "-cursorLeft";
  # }
  # {
  #   key = "up";
  #   command = "-cursorUp";
  # }
  # {
  #   key = "down";
  #   command = "-cursorDown";
  # }
  {
    key = "alt+x";
    command = "-comment-divider.makeSubHeader";
  }
  {
    key = "alt+y";
    command = "-comment-divider.insertSolidLine";
  }
]
