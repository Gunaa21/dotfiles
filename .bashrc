#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


# ── Prompt colours ────────────────────────────────────────────
_c_reset='\[\e[0m\]'
_c_user='\[\e[38;2;137;180;250m\]'       # blue   — username
_c_at='\[\e[38;2;147;153;178m\]'         # grey   — @
_c_host='\[\e[38;2;166;227;161m\]'       # green  — hostname
_c_sep='\[\e[38;2;147;153;178m\]'        # grey   — separator
_c_path='\[\e[38;2;203;166;247m\]'       # purple — full path
_c_git='\[\e[38;2;249;226;175m\]'        # yellow — git branch
_c_prompt='\[\e[38;2;243;139;168m\]'     # pink   — $ symbol

# ── Git branch ────────────────────────────────────────────────
_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
    echo " on ${branch}"
}

# ── Build prompt ──────────────────────────────────────────────
_set_prompt() {
    local git_info
    git_info=$(_git_branch)

    PS1="${_c_user}\u${_c_at}@${_c_host}\h"
    PS1+="${_c_sep} 󰉋 "
    PS1+="${_c_path}\w"                        # \w = full path
    PS1+="${_c_git}${git_info}"
    PS1+=$'\n'                                 # newline before $
    PS1+="${_c_prompt}❯ ${_c_reset}"
}

PROMPT_COMMAND="_set_prompt"

