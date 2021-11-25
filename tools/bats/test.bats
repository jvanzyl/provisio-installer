#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

# We are pulling from Git using "master", but the displayed version is 1.5.0. But then
# the tag in Git is v1.5.0 no 1.5.0. Just inconsistent.

@test "Test BATS installation" {
  version=$(toolVersion bats)
  result=$(bats --version)
  echo ${result} | grep "Bats *"
  result=$(which bats)
  [ -x "${result}" ]  
}
