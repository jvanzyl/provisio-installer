#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Eksctl installation" {
  version=$(toolVersion eksctl)
  result=$(eksctl version)
  echo ${result} | grep "${version}"
  result=$(which eksctl)
  [ -x "${result}" ]  
}
