#!/usr/bin/env bash

provisioFunctions=${1}
profileYaml=${2}
installLocation=${8}

source ${provisioFunctions}
create_variables ${profileYaml}

for tool in ${tools_nodejs_tools[*]}
do
  ${installLocation}/bin/npm install --global ${tool}
done
