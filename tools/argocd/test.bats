#!/usr/bin/env bats

source ${PROVISIO_ROOT}/libexec/provisio-functions.bash

@test "Test ArgoCD CLI installation" {
  tool="argocd"
  version=$(toolVersion ${tool})
  result=$(which ${tool})
  [ -x "${result}" ]  
  # fails because it can't connect to a cluster
  #result=$(${tool} version)
  #echo ${result} | grep "argocd: v${version}"
}
