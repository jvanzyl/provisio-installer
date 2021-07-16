#!/usr/bin/env bash

# provisioFunctions=$1
# profileYaml=$2
# profileBinDirectory=$3
# file=$4

provisioFunctions=$1
profile=$2
bin=$3
file=$4

[ -z "${bin}" ] && exit

(
  cd ${bin}/installs/bats
  rm * .* > /dev/null 2>&1
  rm -rf contrib docs man test
)
