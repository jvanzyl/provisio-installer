#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test NodeJs installation" {
  tool="node"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  result=$(${tool} --version)
  echo ${result} | grep "v${version}"
}
