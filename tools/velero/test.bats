#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Velero installation" {
  tool="velero"  
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  # TODO: velero only reports errors if it can't connect to a cluster
  #result=$(${tool} version)
  #echo ${result} | grep ""
}
