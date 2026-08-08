#!/bin/zsh
# Lotus purple zsh theme

local root_indicator="%{$fg_bold[red]%}%(!.#.λ)%{$reset_color%}"
local user_host="%{$fg_bold[magenta]%}%n%{$reset_color%}@%{$fg[cyan]%}%m%{$reset_color%}"
local current_dir="%{$fg_bold[cyan]%}%~%{$reset_color%}"
local git_branch='$(git_prompt_info)'
local prompt_char="%{$fg_bold[magenta]%}›%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[magenta]%}(%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[magenta]%})%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✓"

PROMPT='${root_indicator} ${user_host} ${current_dir}${git_branch}
${prompt_char} '

PROMPT2="%{$fg[magenta]%}%_› %{$reset_color%}"
RPROMPT="%{$fg[magenta]%}$(command -v >/dev/null && echo '%(?.%{$fg[green]%}✓.%{$fg[red]%}✗)')%{$reset_color%}"
