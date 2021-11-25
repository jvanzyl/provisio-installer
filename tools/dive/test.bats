#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Dive installation" {
  version=$(toolVersion dive)
  result=$(dive --version)
  echo ${result} | grep "dive ${version}"
  result=$(which dive)
  [ -x "${result}" ]  
}
