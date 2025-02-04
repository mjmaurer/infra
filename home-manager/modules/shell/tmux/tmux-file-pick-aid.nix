{ pkgs, ... }: {
  home.packages = [
    # For use in aider
    # Bound to prefix-f
    (pkgs.writeShellScriptBin "tmux-file-pick" ''
      # eval "$(tmux show-environment -s)"
      pane_dir=$(tmux display-message -p '#{pane_current_path}')
      pane_id=$(tmux display-message -p '#{pane_id}')
      cd "$pane_dir" || exit
      git_root=$(git rev-parse --show-toplevel)

      # Running this via popup doesn't include default fzf / fd opts.
      # The eval at the top may fix this
      selected_files=$(
      	fd --type f --hidden --exclude .git |
      		fzf --multi --reverse \
            --min-height=20 --border \
            --border-label-pos=2 \
            --color='header:italic:underline,label:blue' \
            --preview-window='right,60%,border-left' \
            --bind='pgdn:preview-half-page-down' \
            --bind='pgup:preview-half-page-up' \
      			--preview 'bat --style=numbers --color=always {}' |
      		while read -r file; do
      			${pkgs.uutils-coreutils-noprefix}/bin/realpath --relative-to="$git_root" "$pane_dir/$file"
      		done
      )

      if [ -n "$selected_files" ]; then
      	files_oneline=$(echo "$selected_files" | tr '\n' ' ' | sed 's/ $//')
      	tmux send-keys -t "$pane_id" "$files_oneline"
      fi
    '')
  ];

}
