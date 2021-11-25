#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Go Releaser installation" {
  version=$(toolVersion goreleaser)
  result=$(goreleaser --version)
  echo ${result} | grep "goreleaser version ${version}"
  result=$(which goreleaser)
  [ -x "${result}" ]  
}
