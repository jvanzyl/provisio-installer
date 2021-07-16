#!/usr/bin/env bash

# provisioFunctions=$1
# profileYaml=$2
# profileBinDirectory=$3
# file=$4

provisioFunctions=$1
profile=$2
bin=$3
file=$4
url=$5
version=$6

GNUPG_HOME=${bin}/installs/gnupg
mkdir -p ${GNUPG_HOME} > /dev/null 2>&1

work=$(mktemp -d)
output=${GNUPG_HOME}

curl -#OL ${url}
#
# This creates something like /Volumes/GnuPG 2.3.0 where the directory structure
# is like the following:
#
# GnuPG\ 2.3.0
# ├── Install.pkg
# ├── License.txt
# └── Read\ Me.rtf
#
hdiutil attach ${file}
cd "/Volumes/GnuPG ${version}"
# The PKG format is an XAR'd directory structure, which contains a gzipped
# CPIO archive which contains our aws-cli utilities.
#
# XAR'ing the GnuPG.pkg file yields the following directory structure:
#
# GnuPG.pkg
# ├── Bom
# ├── PackageInfo
# ├── Payload
# └── Scripts
#
# The Payload file is the gzipped CPIO archive and it has leading `aws-cli/` entries
#
# Current version of XAR doesn't work with pipes or streams as noted in the
# man pages, so we have to extract the PKG file and deal with the
# individual files.
#
xar -C ${work} -xf Install.pkg
cd ${output}
gzcat ${work}/GnuPG.pkg/Payload | cpio -id
rm -rf ${work}
umount "/Volumes/GnuPG ${version}"
