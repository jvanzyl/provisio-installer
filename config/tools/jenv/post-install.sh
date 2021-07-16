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

source ${provisioFunctions}
create_variables $profile
JENV_ROOT=${HOME}/.jenv
mkdir -p ${JENV_ROOT}/plugins 2>&1

for plugin in ${tools_jenv_plugins[*]}
do
  ln -s \
    ${installLocation}/available-plugins/${plugin} \
    ${JENV_ROOT}/plugins/${plugin}
done
