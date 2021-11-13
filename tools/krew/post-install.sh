#!/usr/bin/env bash

provisioFunctions=${1}
profile=${2}
bin=${3}
filename=${4}
url=${5}
version=${6}
id=${7}
installLocation=${8}
os=${9}
arch=${10}

source ${provisioFunctions}
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
