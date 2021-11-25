#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

# We are pulling from Git using "master", but the displayed version is 1.5.0. But then
# the tag in Git is v1.5.0 no 1.5.0. Just inconsistent.

@test "Test DIMG installation" {
  version=$(toolVersion dimg)
  result=$(dimg --help)
  echo ${result} | grep "dimg *"
  result=$(which dimg)
  [ -x "${result}" ]
}
