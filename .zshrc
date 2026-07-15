#!/bin/zsh
#
# SPDX-FileCopyrightText: Majaahh
# SPDX-License-Identifier: Apache-2.0
#

# [
EXPORT_PATH()
{
    for d in "$@"; do
        if [[ -d "$d" ]]; then
            export PATH="$PATH:$d"
        fi
    done
}

export ZSH="$HOME/.oh-my-zsh"
# ]

plugins=("git")

for f in "zsh-completions" "zsh-history-substring-search" "zsh-syntax-highlighting"; do
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins/$f" ]]; then
        plugins+=("$f")
    fi
done

source "$ZSH/oh-my-zsh.sh"

alias l="ls"
alias la="ls -a"
alias rm="doas rm"
alias cp="cp -rfa"
alias v="$EDITOR"

alias gcl="git clone -j$(nproc --all)"
alias gad="git add"
alias gcm="git commit -s -m"
alias gra="git remote add"
alias gpu="git push -u"
alias gin="git init"
alias gbr="git branch"
alias gpl="git pull -j$(nproc --all)"
alias gru="git remote update"
alias gcp="git cherry-pick -s"
alias gcs="git cherry-pick --skip"
alias gst="git status"
alias grm="git remote remove"
alias gck="git checkout"
alias grv="git revert -s"
alias grc="git revert --continue"
alias grs="git restore --staged"
alias grb="git revert --abort"
alias grn="git revert --no-edit -S -s"
alias gco="git commit -s"
alias gca="git commit -s --amend"
alias gmr="git merge -S --signoff --log"
alias gms="git merge --skip"
alias gma="git merge --abort"
alias gre="git restore"
alias glo="git --no-pager log --oneline"

alias ins="$ROOT emerge -navq"
alias sup="$ROOT emerge --sync && doas emerge -avq --changed-use --newuse --update --deep @world"
alias up="$ROOT emerge -avq --changed-use --newuse --update --deep @world"

EXPORT_PATH \
    "$HOME/.bin" \
    "$HOME/.local/bin" \
    "$HOME/.local/lib" \
    "$HOME/.local/share/flatpak/exports/share/applications"

setopt auto_cd
setopt correct_all
setopt hist_reduce_blanks
setopt hist_ignore_space
setopt hist_save_no_dups
