#!/usr/bin/env bash

version=${6}
installLocation=${8}
os=${9}
profileBinaryDirectory=${11}

# The tarball 
graalDirectory="${installLocation}/graalvm-ce-java11-${version}"

if [ "${os}" = "darwin" ]; then
  ${graalDirectory}/Contents/Home/bin/gu install native-image
elif [ "${os}" = "linux" ]; then
  ${graalDirectory}/bin/gu install native-image
fi
