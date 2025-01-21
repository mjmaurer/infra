#!/bin/bash
# Matches the Alacritty terminal's tmux session to the focused VSCode window's project

# Get session name from focused code window, else ""
SESSION_NAME=$(aerospace list-windows --focused | awk -F' [|] ' '{print $2, $3}' | grep '^Code' | awk -F' — ' '{print $2}' | xargs -I {} bash -c 'if [ -n "{}" ]; then echo "{}"; fi')
# NOT=$($SESSION_NAME | echo "no-session")
# osascript -e "display notification \"$NOT\" with title \"$NOT\""

if [ -n "$SESSION_NAME" ]; then
    # nog=$(which tmux | echo "no-tmux")
    # osascript -e "display notification \"$nog\" with title \"asdfsdf\""
    # Find non-vscode tmux clients and switch them to the session
    tmux list-clients | awk -F: '{print $1}' | while read full_device; do
        device=$(echo "$full_device" | awk -F'/' '{print $NF}')
        if ! ps -ef | grep "$device" | grep -q "vscode_tmux"; then
            # osascript -e "display notification \"$full_device\" with title \"$full_device\""
            tmux switch-client -c "$full_device" -t "$SESSION_NAME";
        fi
    done
fi
