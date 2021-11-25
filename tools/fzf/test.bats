#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test FZF installation" {
  version=$(toolVersion fzf)
  result=$(fzf --version)
  echo ${result} | grep "${version} *"
  result=$(which fzf)
  [ -x "${result}" ]  
}
