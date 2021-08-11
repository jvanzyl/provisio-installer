#!/usr/bin/env bash

# provisioFunctions=$1
# profileYaml=$2
# profileBinDirectory=$3
# file=$4

bin=${3}
installLocation=${8}

[ -z "${bin}" ] && exit

(
  cd ${installLocation}
  rm * .* > /dev/null 2>&1
  rm -rf contrib docs man test
)
