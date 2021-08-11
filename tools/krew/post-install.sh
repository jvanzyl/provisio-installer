#!/usr/bin/env bash

# provisioFunctions=$1
# profileYaml=$2
# profileBinDirectory=$3
# file=$4

source $1
profile=$2
bin=$3

create_variables $profile

for plugin in ${tools_krew_plugins[*]}
do
  ${bin}/krew install $plugin
done

# Use the names that are documented on the site
(
  cd $HOME/.krew/bin
  [ ! -h kubectx ] && ln -s kubectl-ctx kubectx
  [ ! -h kubens ] && ln -s kubectl-ns kubens
)
