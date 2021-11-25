#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test AWS CLI installation" {
  version=$(toolVersion aws_cli)
  result=$(aws --version)
  echo ${result} | grep "aws-cli/${version}"
  result=$(which aws)
  [ -x "${result}" ]  
}
