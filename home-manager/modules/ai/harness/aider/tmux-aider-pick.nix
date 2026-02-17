{ pkgs, ... }:
let
  fzf-cmd = ''
    fzf --reverse \
      --min-height=20 --border \
      --border-label-pos=2 \
      --color='header:italic:underline,label:blue'
  '';
in
{
  home.packages = [
    # Bound to prefix-a
    (pkgs.writeShellScriptBin "tmux-aider-model" ''
      pane_dir=$(tmux display-message -p '#{pane_current_path}')
      pane_id=$(tmux display-message -p '#{pane_id}')
      cd "$pane_dir" || exit

      selected=$(
         echo -e "${
           builtins.concatStringsSep "\\n" [
             "o1"
             "sonnet"
             "o1-mini"
             "4"
             "4o"
             "opus"
           ]
         }" | ${fzf-cmd}
      )

      if [ -n "$selected" ]; then
      	# oneline=$(echo "$selected" | tr '\n' ' ' | sed 's/ $//')
      	tmux send-keys -t "$pane_id" "/model $selected"
      fi
    '')
    # Bound to prefix-m
    # (pkgs.writeShellScriptBin "tmux-aider-mode" ''
    #   pane_dir=$(tmux display-message -p '#{pane_current_path}')
    #   pane_id=$(tmux display-message -p '#{pane_id}')
    #   cd "$pane_dir" || exit

    #   selected=$(
    #   	 echo -e ${
    #       builtins.concatStringsSep "\n" [
    #         "ask"
    #         "code"
    #         "architect"
    #       ]
    #     } | ${fzf-cmd}
    #   )

    #   if [ -n "$selected" ]; then
    #   	oneline=$(echo "$selected_files" | tr '\n' ' ' | sed 's/ $//')
    #   	tmux send-keys -t "$pane_id" "/model $oneline"
    #   fi
    # '')
  ];

}
