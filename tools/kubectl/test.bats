#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Kubectl installation" {
  tool="kubectl"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  # TODO: kubectl emits an error to stderr which confuses BATS
  #result=$(${tool} version)
  #echo ${result} | grep "GitVersion:\"v${version}\""
}
