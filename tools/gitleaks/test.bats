#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Gitleaks installation" {
  version=$(toolVersion gitleaks)
  result=$(gitleaks --version)
  echo ${result} | grep "v${version}"
  result=$(which gitleaks)
  [ -x "${result}" ]
}
