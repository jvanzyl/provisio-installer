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

if [[ ${os} == "darwin" ]]
then
  ${installLocation}/Contents/Home/bin/gu install native-image
elif [[ ${os} == "linux" ]]
then
  ${installLocation}/bin/gu install native-image
fi
