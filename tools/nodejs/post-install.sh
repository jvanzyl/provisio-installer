#!/usr/bin/env bash

provisioFunctions=$1
profileYaml=$2
profileBin=$3

source ${provisioFunctions}
create_variables ${profileYaml}

for tool in ${tools_nodejs_tools[*]}
do
  ${profileBin}/nodejs/bin/npm install --global ${tool}
done
