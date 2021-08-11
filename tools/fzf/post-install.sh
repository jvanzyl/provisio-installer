#!/usr/bin/env bash

# provisioFunctions=$1
# profileYaml=$2
# profileBinDirectory=$3
# file=$4

version=${6}
installLocation=${8}

(
cd ${installLocation}
mkdir bash
  (
    cd bash
    [ ! -f key-bindings.bash ] && curl -OL https://raw.githubusercontent.com/junegunn/fzf/${version}/shell/key-bindings.bash
    [ ! -f completion.bash ] && curl -OL https://raw.githubusercontent.com/junegunn/fzf/${version}/shell/completion.bash
  )
mkdir zsh
  (
    cd zsh
    [ ! -f key-bindings.zsh ] && curl -OL https://raw.githubusercontent.com/junegunn/fzf/${version}/shell/key-bindings.zsh
    [ ! -f completion.zsh ] && curl -OL https://raw.githubusercontent.com/junegunn/fzf/${version}/shell/completion.zsh
  )
)
