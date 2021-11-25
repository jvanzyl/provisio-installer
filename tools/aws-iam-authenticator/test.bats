#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test AWS IAM Authenticator installation" {
  tool="aws_iam_authenticator"
  version=$(toolVersion ${tool})
  result=$(which aws-iam-authenticator)
  [ -x "${result}" ]
  # TODO: output is {"Version":"unversioned"}
  #result=$(${tool} version)
  #echo ${result} | grep "{\"Version\":\"${version\"}"
}
