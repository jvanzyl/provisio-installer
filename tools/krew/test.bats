#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Krew installation" {
  tool="krew"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]
  result=$(${tool} version)
  echo ${result} | grep "${version}"
}

@test "Test Krew plugins installation" {
  # Test the installation of krew plugins
  result=$(which kubectl-ctx)
  [ -x "${result}" ]
  result=$(which kubectl-konfig)
  [ -x "${result}" ]
  result=$(which kubectl-ns)
  [ -x "${result}" ]
}
