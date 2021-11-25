#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test VSCodium installation" {
  tool="vscodium"
  version=$(toolVersion ${tool})
  result=$(which vscode)
  [ -x "${result}" ]  
  result=$(vscode --version)
  echo ${result} | grep "${version}"
}
