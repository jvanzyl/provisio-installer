#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test Google Cloud SDK installation" {
  tool="gcloud"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  result=$(${tool} version)
  echo ${result} | grep "Google Cloud SDK ${version}"
}
