#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Sops installation" {
  tool="sops"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  result=$(${tool} --version)
  echo ${result} | grep "sops ${version}"
}
