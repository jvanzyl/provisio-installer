#!/usr/bin/env bash

provisioFunctions=${1}
profileYaml=${2}
installLocation=${8}

source ${provisioFunctions}
create_variables ${profileYaml}
JENV_ROOT=${HOME}/.jenv
mkdir -p ${JENV_ROOT}/plugins 2>&1

for plugin in ${tools_jenv_plugins[*]}
do
  ln -s \
    ${installLocation}/available-plugins/${plugin} \
    ${JENV_ROOT}/plugins/${plugin}
done
