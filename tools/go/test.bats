#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Go installation" {
  version=$(toolVersion go)
  result=$(go version)
  echo ${result} | grep "go version go${version} *"
  result=$(which go)
  [ -x "${result}" ]  
}
