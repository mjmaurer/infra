{ keymapName }:
''
  <keymap version="1" name="${keymapName}" parent="$default">
    <!-- Terminal toggle: alt+t -->
    <action id="ActivateTerminalToolWindow">
      <keyboard-shortcut first-keystroke="alt t" />
    </action>

    <!-- Debug test at cursor: alt+e -->
    <action id="DebugClass">
      <keyboard-shortcut first-keystroke="alt e" />
    </action>

    <!-- Debug current file: alt+shift+e -->
    <action id="Debug">
      <keyboard-shortcut first-keystroke="alt shift e" />
    </action>

    <!-- Rerun: alt+r -->
    <action id="Rerun">
      <keyboard-shortcut first-keystroke="alt r" />
    </action>

    <!-- Stop debug: alt+q -->
    <action id="Stop">
      <keyboard-shortcut first-keystroke="alt q" />
    </action>

    <!-- Disconnect debug: alt+x -->
    <action id="Disconnect">
      <keyboard-shortcut first-keystroke="alt x" />
    </action>

    <!-- Resume/continue debug: alt+c -->
    <action id="Resume">
      <keyboard-shortcut first-keystroke="alt c" />
    </action>

    <!-- Code completion: alt+d -->
    <action id="CodeCompletion">
      <keyboard-shortcut first-keystroke="alt d" />
    </action>

    <!-- Hide all tool windows: alt+escape -->
    <action id="HideAllWindows">
      <keyboard-shortcut first-keystroke="alt escape" />
    </action>

    <!-- Toggle project sidebar: alt+i -->
    <action id="ActivateProjectToolWindow">
      <keyboard-shortcut first-keystroke="alt i" />
    </action>

    <!-- Select in project view: alt+shift+i -->
    <action id="SelectInProjectView">
      <keyboard-shortcut first-keystroke="alt shift i" />
    </action>

    <!-- Show diff for changed lines: alt+g -->
    <action id="Vcs.ShowDiffChangedLines">
      <keyboard-shortcut first-keystroke="alt g" />
    </action>

    <!-- Next VCS change marker: cmd+[ -->
    <action id="VcsShowNextChangeMarker">
      <keyboard-shortcut first-keystroke="meta open_bracket" />
    </action>
  </keymap>
''
