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
profileBinaryDirectory=${11}

source ${provisioFunctions}
create_variables $profile

# It seems like it's not possible to put the krew binary in the ${KREW_ROOT}/bin or yout
# get a "krew home outdated" error. So to work around this we put the krew binary in the normal
# provisio binary directory and make a krew-root directory in the profile binary directory. But
# this at least keeps krew from contaminating ${HOME}.
# TODO: report a bug with a test

export KREW_ROOT=${installLocation}
#export KREW_ROOT=${profileBinaryDirectory}/krew
mkdir -p ${KREW_ROOT}/bin 2>&1

# Krew is packaged oddly, but we want to make a self-contained installation
# where everything released to krew is in one directory.
mv ${KREW_ROOT}/krew-${os}_${arch} ${KREW_ROOT}/krew

for plugin in ${tools_krew_plugins[*]}
do
  ${KREW_ROOT}/krew install ${plugin}
done
