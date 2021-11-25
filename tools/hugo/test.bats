#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Hugo installation" {
  tool="hugo"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  result=$(${tool} version)
  echo ${result} | grep "hugo v${version}"
}
