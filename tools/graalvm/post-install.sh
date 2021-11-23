#!/usr/bin/env bash

installLocation=${8}
os=${9}

if [ "${os}" = "darwin" ]; then
  ${installLocation}/Contents/Home/bin/gu install native-image
elif [ "${os}" = "linux" ]; then
  ${installLocation}/bin/gu install native-image
fi
