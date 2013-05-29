# skrieg


# example of background colour
# foreground white = 37
# background red = 41
fgwhitebgred="%{^[[0;37;41m%}"



# Lines configured by zsh-newuser-install

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/skrieg/.zshrc'

setopt interactivecomments

autoload -Uz compinit
compinit
# End of lines added by compinstall



#########
# aliases
#########

# command alias
alias ls='ls -F --color=auto' 
alias ll='ls -lh'
alias grep='grep --color=auto' 




########
# Prompt
########

function loadavg1 {
    awk '{print  $1}' /proc/loadavg
}
# couleurs
# valid colors: Red, Blue, Green, Cyan, Yellow, Magenta, Black 
# colors: http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html#SEC59
autoload -U colors && colors


if [[ "$terminfo[colors]" -ge 8 ]]; then
  if [[ "$EUID" = "0" ]] || [[ "$USER" = 'root' ]]
  then
    username_color=%F{red}
  else
    username_color=%F{green}
  fi
fi


setopt PROMPT_SUBST
setopt promptsubst
setopt promptpercent


PROMPT=""
# return status (in colors plz!)
# http://stackoverflow.com/a/4466959/238913
# http://zshwiki.org/home/scripting/paramflags

# test1
#write exit code if not zero
local e_code="%(?..%F{red}%? %f)"
PROMPT=$e_code
local smiley="%(?,%{$fg[green]%}:)%{$reset_color%},%{$fg[red]%}:(%{$reset_color%})"
#PROMPT=$smiley

# [time]
# les deux lignes font bouger l'heure!(incompatible avec "%?")
#_prompt_and_resched() { sched +1 _prompt_and_resched; zle && zle reset-prompt }
#_prompt_and_resched
GREY=$'\e[30;1m'
NORMAL=$'\e[0m'
PROMPT=${PROMPT}%{${GREY}%}[%*]%{${NORMAL}%}

# user@hostname
PROMPT=${PROMPT}"$username_color%n%f@%M%f:"
# current directory and shell opening: %=user , #=root
PROMPT=$PROMPT"%F{blue}%~%f ${username_color}%#%f "
# right prompt
RPROMPT="$(loadavg1)"
