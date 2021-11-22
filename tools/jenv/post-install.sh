#!/usr/bin/env bash

provisioFunctions=${1}
profileYaml=${2}
installLocation=${8}
profileBinaryDirectory=${11}

source ${provisioFunctions}
create_variables ${profileYaml}
export JENV_ROOT=${installLocation}
mkdir -p ${JENV_ROOT}/{plugins,versions} 2>&1

for plugin in ${tools_jenv_plugins[*]}
do
  ln -s \
    ${installLocation}/available-plugins/${plugin} \
    ${JENV_ROOT}/plugins/${plugin}
done

# TODO: (multiple-runtimes) Here we are introducing an implicit relationship of jenv on java. The descriptor
# should be changed to reflect this and also order the installation of tools as java needs to be installed
# before jenv can add JDKs
for jdk in $(ls ${profileBinaryDirectory}/java)
do
  ${JENV_ROOT}/bin/jenv add "${profileBinaryDirectory}/java/${jdk}/Contents/Home"
done

for jdk in $(ls ${profileBinaryDirectory}/graalvm)
do
  ${JENV_ROOT}/bin/jenv add "${profileBinaryDirectory}/graalvm/${jdk}/Contents/Home"
done

[ ! -z "${tools_jenv_global}" ] && ${JENV_ROOT}/bin/jenv global ${tools_jenv_global}