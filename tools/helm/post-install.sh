#!/usr/bin/env bash

# provisioFunctions=$1
# profileYaml=$2
# profileBinDirectory=$3
# file=$4

source $1
profile=$2
bin=$3

create_variables $profile

for plugin in ${tools_helm_plugins[*]}
do
  ${bin}/helm plugin install $plugin
done
