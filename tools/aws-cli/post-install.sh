#!/usr/bin/env bash

provisioFunctions=${1}
profile=${2}
bin=${3}
filename=${4}
url=${5}
version=${6}
id=${7}
installLocation=${8}
os=${9}
source ${provisioFunctions}
AWS_CLI_HOME=${installLocation}
mkdir -p ${AWS_CLI_HOME} > /dev/null 2>&1

# The PKG format is an XAR’d directory structure, which contains a gzipped
# CPIO archive which contains our aws-cli utilities.
#
# XAR’ing the AWSCLIV2.pkg file yields the following directory structure:
#
# aws-cli.pkg
# ├── Bom
# ├── PackageInfo
# ├── Payload
# └── Scripts
#
# The Payload file is the gzipped CPIO archive and it has leading `aws-cli/` entries
#
# Current version of XAR doesn’t work with pipes or streams as noted in the
# man pages, so we have to extract the PKG file and deal with the
# individual files.
#

work=$(mktemp -d)
file=$(retrieveArtifact ${id} ${version} ${url} ${filename})

if [ "${os}" = "Darwin" ]; then
  xar -C ${work} -xf ${file}
  cd ${installLocation}
  # This unpack the archive in ${bin}/aws-cli/{version}/aws-cli
  gzcat ${work}/aws-cli.pkg/Payload | cpio -id
  # Doesn't seem to be a way to strip the leading entry as with tar so we have to move
  # the files up one directory to make the layout consistent with Linux
  mv ${installLocation}/aws-cli/* ${installLocation}
  # Remove the straggling empty directory
  rm -rf ${installLocation}/aws-cli 
  rm -rf ${work}
  # This in the path creates a problem with any Python installed
  # on the target machine
  chmod -x ${AWS_CLI_HOME}/Python
elif [ "${os}" = "Linux" ]; then
  # This works cross installing on Darwin, there’s just an error
  # message about not being able to execute a script but otherwise
  # the installation carries on.
  #
  # -i = installation directory
  # -b = directory to create symlinks to aws: doesn’t work cross OS
  unzip ${file} -d /tmp
  /tmp/aws/install -i ${installLocation} -b ${bin}
  rm -rf /tmp/aws
fi
