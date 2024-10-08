set -o vi

export PATH="$HOME/.local/bin:$PATH"

# unbind alt keys
bind -r '\ei'
bind -r '\ea'
bind -r '\ef'
bind -r '\em'

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] ; then
    PS1="\[\e[1;32m\]\u@\[\e[1;32m\]\h"
  else
    PS1=""
fi

# bash prompt
PS1+="\[\e[1;36m\]\w\\$ \[\e[0m\]"
export PS1

# -------------------------- 

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth:erasedups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=100000

export PROMPT_COMMAND="history -a; history -c; history -r;"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

  # set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
# force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
      # We have color support; assume it's compliant with Ecma-48
      # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
      # a case would tend to support setf rather than setaf.)
      color_prompt=yes
  else
      color_prompt=
  fi
fi

unset color_prompt force_color_prompt

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
  fi
fi

LS_COLORS=$LS_COLORS':no=00'
LS_COLORS=$LS_COLORS':di=36;01'
LS_COLORS=$LS_COLORS':tw=36;01'
LS_COLORS=$LS_COLORS':ow=36;01'
LS_COLORS=$LS_COLORS':fi=93'
LS_COLORS=$LS_COLORS':ln=00'
LS_COLORS=$LS_COLORS':pi=00'
LS_COLORS=$LS_COLORS':so=00'
LS_COLORS=$LS_COLORS':ex=00'
LS_COLORS=$LS_COLORS':bd=00'
LS_COLORS=$LS_COLORS':cd=00'
LS_COLORS=$LS_COLORS':or=00'
LS_COLORS=$LS_COLORS':mi=00'
LS_COLORS=$LS_COLORS':*.sh=31'
LS_COLORS=$LS_COLORS':*.sh=31'
LS_COLORS=$LS_COLORS':*.exe=31'
LS_COLORS=$LS_COLORS':*.bat=31'
LS_COLORS=$LS_COLORS':*.com=31'
export LS_COLORS
