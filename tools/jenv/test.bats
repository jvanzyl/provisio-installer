#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test JEnv installation" {
  tool="jenv"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]
  result=$(${tool} --version)
  # This is master but it hasn't changed in a while, it will fail when it does
  # which we want to see
  echo ${result} | grep "jenv 0.5.4"
}

# Test all JDKs are installed
# Test global
# Test local
