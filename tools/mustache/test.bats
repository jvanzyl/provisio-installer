#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Mustache installation" {
  tool="mustache"  
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  # No version output
  #result=$(${tool} version)
  #echo ${result} | grep "kind v${version} *"
}
