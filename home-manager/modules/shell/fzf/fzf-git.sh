# ------------------------------------ FZF: Git ------------------------------------ #
# https://github.com/junegunn/fzf-git.sh

# shellcheck disable=SC2039
[[ $0 = - ]] && return


__fzf_git_color() {
  if [[ -n $NO_COLOR ]]; then
    echo never
  elif [[ $# -gt 0 ]] && [[ -n $FZF_GIT_PREVIEW_COLOR ]]; then
    echo "$FZF_GIT_PREVIEW_COLOR"
  else
    echo "${FZF_GIT_COLOR:-always}"
  fi
}

__fzf_git_cat() {
  if [[ -n $FZF_GIT_CAT ]]; then
    echo "$FZF_GIT_CAT"
    return
  fi

  # Sometimes bat is installed as batcat
  _fzf_git_bat_options="--style='${BAT_STYLE:-full}' --color=$(__fzf_git_color .) --pager=never"
  if command -v batcat > /dev/null; then
    echo "batcat $_fzf_git_bat_options"
  elif command -v bat > /dev/null; then
    echo "bat $_fzf_git_bat_options"
  else
    echo cat
  fi
}

__fzf_git_pager() {
  local pager
  pager="${FZF_GIT_PAGER:-${GIT_PAGER:-$(git config --get core.pager 2>/dev/null)}}"
  echo "${pager:-cat}"
}

if [[ $# -eq 1 ]]; then
  branches() {
    git branch "$@" --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=$(__fzf_git_color) | column -ts$'\t'
  }
  refs() {
    git for-each-ref "$@" --sort=-creatordate --sort=-HEAD --color=$(__fzf_git_color) --format=$'%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)\t%(color:yellow)%(refname:short) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' | column -ts$'\t'
  }
  hashes() {
    git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=$(__fzf_git_color) "$@"
  }
  all-diffs() {
    git log --color=always --date=short --pretty=format:'START %cd %h%d %s' -p -U0 | awk 'BEGIN{RS="START "}/./{gsub(/\n/," "); print}'
  }
  case "$1" in
    branches)
      echo $'CTRL-O (open in browser) ╱ ALT-A (show all branches)\n'
      branches
      ;;
    all-branches)
      echo $'CTRL-O (open in browser)\n'
      branches -a
      ;;
    all-diffs)
      echo $'Enter (fzf show) ╱ CTRL-S (toggle sort)\n'
      all-diffs
      ;;
    hashes)
      echo $'CTRL-O (open in browser) ╱ CTRL-D (diff)\nCTRL-S (toggle sort) ╱ ALT-A (show all hashes)\n'
      hashes
      ;;
    all-hashes)
      echo $'CTRL-O (open in browser) ╱ CTRL-D (diff)\nCTRL-S (toggle sort)\n'
      hashes --all
      ;;
    refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor) ╱ ALT-A (show all refs)\n'
      refs --exclude='refs/remotes'
      ;;
    all-refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor)\n'
      refs
      ;;
    nobeep) ;;
    *) exit 1 ;;
  esac
elif [[ $# -gt 1 ]]; then
  set -e

  branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [[ $branch = HEAD ]]; then
    branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
  fi

  diff() {
    # git show --pretty=format:"" -U0 HEAD~4 | awk 'BEGIN{RS="diff --git"; FS="\n"} {gsub(/\n/, " "); for (i = 1; i <= NF; i++) if ($i ~ /^--- a\// || $i ~ /^\+\+\+ b\//) print $1, $i; else if ($i ~ /^diff --git/) print $1; }'
    if [[ -z "$1" && -z "$2" ]]; then
      git diff --pretty=format:"" --name-only
    else
      git diff --pretty=format:"" --name-only "$1" "$2"
    fi
  }

  skip_remote=false
  # Only supports GitHub for now
  case "$1" in
    commit)
      hash=$(grep -o "[a-f0-9]\{7,\}" <<< "$2")
      path=/commit/$hash
      ;;
    diff)
      echo $'Enter (open file in difftool) ╱ CTRL-S (toggle sort) ╱\nCTRL-A (show all diffs)\n'
      diff $2 $3
      skip_remote=true
      ;;
    branch|remote-branch)
      branch=$(sed 's/^[* ]*//' <<< "$2" | cut -d' ' -f1)
      remote=$(git config branch."${branch}".remote || echo 'origin')
      branch=${branch#$remote/}
      path=/tree/$branch
      ;;
    remote)
      remote=$2
      path=/tree/$branch
      ;;
    file) path=/blob/$branch/$(git rev-parse --show-prefix)$2 ;;
    tag)  path=/releases/tag/$2 ;;
    *)    exit 1 ;;
  esac

  remote=${remote:-$(git config branch."${branch}".remote || echo 'origin')}
  remote_url=$(git remote get-url "$remote" 2> /dev/null || echo "$remote")

  if [[ $remote_url =~ ^git@ ]]; then
    url=${remote_url%.git}
    url=${url#git@}
    url=https://${url/://}
  elif [[ $remote_url =~ ^http ]]; then
    url=${remote_url%.git}
  fi

  if [[ $skip_remote = false ]]; then
    case "$(uname -s)" in
      Darwin) open "$url$path"     ;;
      *)      xdg-open "$url$path" ;;
    esac
    exit 0
  fi
fi

if [[ $- =~ i ]]; then
# -----------------------------------------------------------------------------

_fzf_git_fzf() {
    # git-fzf default fzf options
    # You can see the original in fzf-git.sh
    fzf --height=50% --tmux 90%,90% \
    --layout=reverse --multi --min-height=20 --border \
    --border-label-pos=2 \
    --color='header:italic:underline,label:blue' \
    --preview-window='down,70%,border-top' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' \
    "$@"
}


_fzf_git_check() {
  git rev-parse HEAD > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  return 1
}

__fzf_git=${BASH_SOURCE[0]:-${(%):-%x}}
__fzf_git=$(readlink -f "$__fzf_git" 2> /dev/null || /usr/bin/ruby --disable-gems -e 'puts File.expand_path(ARGV.first)' "$__fzf_git" 2> /dev/null)

_fzf_git_files() {
  _fzf_git_check || return
  local root query
  root=$(git rev-parse --show-toplevel)
  [[ $root != "$PWD" ]] && query='!../ '

  (git -c color.status=$(__fzf_git_color) status --short --no-branch
   git ls-files "$root" | grep -vxFf <(git status -s | grep '^[^?]' | cut -c4-; echo :) | sed 's/^/   /') |
  _fzf_git_fzf -m --ansi --nth 2..,.. \
    --border-label '📁 Files' \
    --header $'CTRL-O (open in browser) ╱ ALT-E (open in editor)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git file {-1}" \
    --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
    --query "$query" \
    --preview-window='down,75%,border-top' \
    --preview "git diff --no-ext-diff --color=$(__fzf_git_color .) -- {-1} | $(__fzf_git_pager); $(__fzf_git_cat) {-1}" "$@" |
  cut -c4- | sed 's/.* -> //'
}

_fzf_git_branches() {
  _fzf_git_check || return
  bash "$__fzf_git" branches |
  _fzf_git_fzf --ansi \
    --border-label '🌲 Branches' \
    --header-lines 2 \
    --tiebreak begin \
    --preview-window down,border-top,50% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git branch {}" \
    --bind "alt-a:change-border-label(🌳 All branches)+reload:bash \"$__fzf_git\" all-branches" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' \$(sed s/^..// <<< {} | cut -d' ' -f1) --" "$@" |
  sed 's/^..//' | cut -d' ' -f1
}

_fzf_git_tags() {
  _fzf_git_check || return
  git tag --sort -version:refname |
  _fzf_git_fzf --preview-window down,70% \
    --border-label '📛 Tags' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git tag {}" \
    --preview "git show --color=$(__fzf_git_color .) {} | $(__fzf_git_pager)" "$@"
}


_fzf_git_diff() {
  # File-by-file diff between two specific commits. 
  _fzf_git_check || return
  local commit1=${1:-}
  # Set to HEAD by default if commit1 is not empty:
  local commit2=${2:-${commit1:+HEAD}}
  local message="Working Diff"
  if [[ -n "$commit1" && -n "$commit2" ]]; then
    message="Diff from ${commit1:0:6} to ${commit2:0:6}"
  fi
  bash "$__fzf_git" diff "$commit1" "$commit2" |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --border-label "$message" \
    --header-lines 3 \
    --bind "enter:execute-silent:git difftool --no-prompt $commit1 $commit2 -- {}" \
    --bind "ctrl-a:become(bash -ic '_fzf_git_all_diffs')" \
    --color hl:underline,hl+:underline \
    --preview "git diff $commit1 $commit2 --color=$(__fzf_git_color .) -- {} | $(__fzf_git_pager)"
}

_fzf_git_show() {
  _fzf_git_diff "$1^" "$1"
}

_fzf_git_all_diffs() {
    # --bind "enter:become(grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs bash $__fzf_git show)" \
    # --bind "enter:become(grep -m 1 -o '[a-f0-9]\{7,\}' <<< {} | xargs bash -ic '_fzf_git_show $(cat)')" \
  _fzf_git_check || return
  bash "$__fzf_git" all-diffs |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --border-label 'All Diffs' \
    --header-lines 3 \
    --bind "ctrl-o:execute-silent:bash $__fzf_git commit {}" \
    --bind "enter:become(export hash=\$(grep -m 1 -o '[a-f0-9]\{7,\}' <<< {} | head -n 1) && bash -ic '_fzf_git_show \"\$hash\"')" \
    --bind "ctrl-a:change-border-label(🍇 All hashes)+reload:bash \"$__fzf_git\" all-hashes" \
    --color hl:underline,hl+:underline \
    --preview "grep -m 1 -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git show --color=$(__fzf_git_color .) | $(__fzf_git_pager)" "$@" |
  awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

_fzf_git_hashes() {
  _fzf_git_check || return
  bash "$__fzf_git" hashes |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --border-label '🍡 Hashes' \
    --header-lines 3 \
    --bind "ctrl-o:execute-silent:bash $__fzf_git commit {}" \
    --bind "ctrl-d:execute:grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git diff --color=$(__fzf_git_color) > /dev/tty" \
    --bind "alt-a:change-border-label(🍇 All hashes)+reload:bash \"$__fzf_git\" all-hashes" \
    --color hl:underline,hl+:underline \
    --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git show --color=$(__fzf_git_color .) | $(__fzf_git_pager)" "$@" |
  awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

_fzf_git_remotes() {
  _fzf_git_check || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  _fzf_git_fzf --tac \
    --border-label '📡 Remotes' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git remote {1}" \
    --preview-window down,70% \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' '{1}/$(git rev-parse --abbrev-ref HEAD)' --" "$@" |
  cut -d$'\t' -f1
}

_fzf_git_stashes() {
  _fzf_git_check || return
  git stash list | _fzf_git_fzf \
    --border-label '🥡 Stashes' \
    --header $'CTRL-X (drop stash)\n\n' \
    --bind 'ctrl-x:reload(git stash drop -q {1}; git stash list)' \
    -d: --preview "git show --color=$(__fzf_git_color .) {1} | $(__fzf_git_pager)" "$@" |
  cut -d: -f1
}

_fzf_git_lreflogs() {
  _fzf_git_check || return
  git reflog --color=$(__fzf_git_color) --format="%C(blue)%gD %C(yellow)%h%C(auto)%d %gs" | _fzf_git_fzf --ansi \
    --border-label '📒 Reflogs' \
    --preview "git show --color=$(__fzf_git_color .) {1} | $(__fzf_git_pager)" "$@" |
  awk '{print $1}'
}

_fzf_git_each_ref() {
  _fzf_git_check || return
  bash "$__fzf_git" refs | _fzf_git_fzf --ansi \
    --nth 2,2.. \
    --tiebreak begin \
    --border-label '☘️  Each ref' \
    --header-lines 2 \
    --preview-window down,border-top,50% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git {1} {2}" \
    --bind "alt-e:execute:${EDITOR:-vim} <(git show {2}) > /dev/tty" \
    --bind "alt-a:change-border-label(🍀 Every ref)+reload:bash \"$__fzf_git\" all-refs" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' {2} --" "$@" |
  awk '{print $2}'
}

_fzf_git_worktrees() {
  _fzf_git_check || return
  git worktree list | _fzf_git_fzf \
    --border-label '🌴 Worktrees' \
    --header $'CTRL-X (remove worktree)\n\n' \
    --bind 'ctrl-x:reload(git worktree remove {1} > /dev/null; git worktree list)' \
    --preview "
      git -c color.status=$(__fzf_git_color .) -C {1} status --short --branch
      echo
      git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' {2} --
    " "$@" |
  awk '{print $1}'
}

if [[ -n "${BASH_VERSION:-}" ]]; then
  __fzf_git_init() {
    bind -m emacs-standard '"\er":  redraw-current-line'
    bind -m emacs-standard '"\C-z": vi-editing-mode'
    bind -m vi-command     '"\C-z": emacs-editing-mode'
    bind -m vi-insert      '"\C-z": emacs-editing-mode'

    local o c
    for o in "$@"; do
      c=${o:0:1}
      bind -m emacs-standard '"\C-g\C-'$c'": " \C-u \C-a\C-k`_fzf_git_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-g\C-'$c'": "\C-z\C-g\C-'$c'\C-z"'
      bind -m vi-insert      '"\C-g\C-'$c'": "\C-z\C-g\C-'$c'\C-z"'
      bind -m emacs-standard '"\C-g'$c'":    " \C-u \C-a\C-k`_fzf_git_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-g'$c'":    "\C-z\C-g'$c'\C-z"'
      bind -m vi-insert      '"\C-g'$c'":    "\C-z\C-g'$c'\C-z"'
    done
  }
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  __fzf_git_join() {
    local item
    while read item; do
      echo -n "${(q)item} "
    done
  }

  __fzf_git_init() {
    local m o
    for o in "$@"; do
      eval "fzf-git-$o-widget() { local result=\$(_fzf_git_$o | __fzf_git_join); zle reset-prompt; LBUFFER+=\$result }"
      eval "zle -N fzf-git-$o-widget"
      for m in emacs vicmd viins; do
        eval "bindkey -M $m '^g^${o[1]}' fzf-git-$o-widget"
        eval "bindkey -M $m '^g${o[1]}' fzf-git-$o-widget"
      done
    done
  }
fi
__fzf_git_init files branches tags remotes hashes stashes lreflogs each_ref worktrees

# -----------------------------------------------------------------------------
fi