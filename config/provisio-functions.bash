#!/usr/bin/env bash

# NOTES:
# https://stackoverflow.com/questions/669452/is-double-square-brackets-preferable-over-single-square-brackets-in-ba

function tool_descriptor() {
  tool=$1
  echo "${PROVISIO_ROOT}/config/tools/${tool}/descriptor.yml"
}

function tool_bash_template() {
  tool=$1
  echo "${PROVISIO_ROOT}/config/tools/${tool}/bash-template.txt"
}

# This handles underscores in a way that breaks standard naming used with
# the previous parser but this handles lists
function parse_yaml_with_lists() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |

        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

        sed -e 's/_=/+=/g' |

        awk 'BEGIN {
                FS="=";
                OFS="="
            }
            /(-|\.).*=/ {
                gsub("-|\\.", "_", $1)
            }
            { print }'
    ) < "$yaml_file"
}

function create_variables() {
    local yaml_file="$1"
    local prefix="$2"
    eval "$(parse_yaml_with_lists "$yaml_file" "$prefix")"
}

function retrieveArtifact() {
  id="${1}"
  version="${2}"
  url="${3}"
  filename="${4}"
  # Given the id, url, and filename of the artifact let's check our cache
  # to see if it's present locally first before attempting to download it.
  file="${PROVISIO_ROOT}/.cache/${id}/${version}/${filename}"
  # Use an inprogress suffix on the file so if the downloading process is
  # interrupted then we can clean up the file and start over if necessary
  fileInProgress="${file}.inprogress"
  parentDirectory=$(dirname ${file})
  if [ ! -f ${file} ]
  then
    if [ ! -d ${parentDirectory} ]
    then
      mkdir -p ${parentDirectory}
    fi
    if [ -f ${fileInProgress} ]
    then
      # Have an inprogress so remove it and start over.
      rm -rf ${fileInProgress}
    fi
    curl -#L -o ${fileInProgress} ${url}
    mv ${fileInProgress} ${file}
  fi
  echo ${file}
}

function provisionTool() {

  # $1 tool profile yaml (required)
  # $2 tool configuration yaml (required)
  # $3 bin directory (required)

  toolProfileYaml=${1}
  toolConfigurationYaml=${2}
  bin=${3}
  version=${4}
  [[ -z ${5} ]] && os=$(uname) || os=${5}
  [[ -z ${6} ]] && arch=$(uname -m) || arch=${6}

  unset id
  unset name
  unset defaultVersion
  unset executable
  unset architecture
  unset namingStyle
  unset packaging
  unset layout
  unset urlTemplate
  unset darwinUrlTemplate
  unset linuxUrlTemplate
  unset tarSingleFileToExtract
  unset installation

  toolDirectory=$(dirname ${toolConfigurationYaml})

  # We are doing everything inside a subshell with the tools directory so that when people
  # write scripts they are relative to the directory with resources that might be referenced

  (

  cd ${toolDirectory}

  if [ -f $yaml ]
  then

    eval $(parse_yaml_with_lists ${toolConfigurationYaml})

    executableLocation="${bin}/${executable}"
    installLocation="${bin}/installs/${id}"

    # Executables are currently all stored in one directory, and installations live
    # in their own directory.

    if [[ ${layout} == "file" ]]
    then
      echo -n "Checking if the executable ${executable} exists here: ${executableLocation} ... "
      [[ -f ${executableLocation} ]] && echo "yes, moving on ..." && return || echo "no, installing ..."
    elif [[ ${layout} == "directory" ]]
    then
      echo -n "Checking if the installation ${id} exists here: ${installLocation} ... "
      [[ -d ${installLocation} ]] && echo "yes, moving on..." && return || echo "no, installing ..."
    fi

    [ ! -d ${bin} ] && mkdir -p ${bin}

    if [ "${os}" = "Darwin" -a ! -z "${darwinUrlTemplate}" ]; then
      urlTemplate=${darwinUrlTemplate}
    elif [ "${os}" = "Linux" -a ! -z "${linuxUrlTemplate}" ]; then
      urlTemplate=${linuxUrlTemplate}
    fi

    # --------------------------------------------------------------------------
    # osMappings:
    #   Darwin: darwin
    #   Linux: linux
    # archMappings:
    #   x86_64: amd64
    # --------------------------------------------------------------------------
    eval 'osMappings=(${!'"osMappings"'@})'
    for i in "${osMappings[@]}"
    do
      # What is returned by $(uname) like Darwin or Linux
      osIdentifier=`echo ${i} | sed 's/osMappings_//'`
      # What the tool uses in its naming like linux os osx
      osIdentifierToolUses=${!i}
      # Transform os identifier
      os=$(echo ${os} | sed -e "s/${osIdentifier}/${osIdentifierToolUses}/")
    done

    eval 'archMappings=(${!'"archMappings_"'@})'
    for i in "${archMappings[@]}"
    do
      # What is returned by $(uname -m) like x86_64
      archIdentifier=`echo ${i} | sed 's/archMappings_//'`
      # What the tool uses in its naming like amd64
      archIdentifierToolUses=${!i}
      # Transform arch identifier
      arch=$(echo ${arch} | sed -e "s/${archIdentifier}/${archIdentifierToolUses}/")
    done

    url=`echo $urlTemplate | \
      sed -e "s@{version}@${version}@g" \
          -e "s@{os}@${os}@g" \
          -e "s@{arch}@${arch}@g"`
    echo
    filename=$(basename $url)

    # Now look at the at the Packaging
    if [ "${packaging}" = "TARGZ" -o "${packaging}" = "TARGZ_STRIP" ]
    then
      # For the TARGZ_STRIP packaging type we need to removing the first directory entry
      [ "${packaging}" = "TARGZ_STRIP" ] && stripComponents="--strip-components 1"
      file=$(retrieveArtifact ${id} ${version} ${url} ${filename})
      if [ ! -z "${tarSingleFileToExtract}" ]; then
        # --------------------------------------------------------------------
        # We have an archive that contains versions for all platforms so once
        # the archive is downloaded we have to extract the single version for
        # the specific target platform
        # --------------------------------------------------------------------
        tarSingleFileToExtract=`echo $tarSingleFileToExtract | \
          sed -e "s@{version}@${version}@g" \
              -e "s@{os}@${os}@g" \
              -e "s@{arch}@${arch}@g"`

        tar xzf ${file} ${tarSingleFileToExtract}
        mv ${tarSingleFileToExtract} ${executableLocation}
      else
        if [ ! -z "${layout}" -a "${layout}" = "directory" ]; then
          mkdir -p ${installLocation} > /dev/null 2>&1
          tar xzf ${file} --strip-components 1 -C ${installLocation}
        else
          tar xzf ${file} ${stripComponents} -C ${bin}
        fi
      fi
    elif [ "${packaging}" = "FILE" ]; then
      file=$(retrieveArtifact ${id} ${version} ${url} ${filename})
      target="${bin}/${executable}"
      cp ${file} ${target}
      chmod +x ${target}
    elif [ "${packaging}" = "ZIP" ]; then
      file=$(retrieveArtifact ${id} ${version} ${url} ${filename})
      unzip -o ${file} -d ${bin}
    elif [ "${packaging}" = "GIT" ]; then
      installDirectory="${bin}/installs/${id}"
      if [ ! -d ${installDirectory} ]; then
        git clone $url ${installDirectory}
        (cd ${installDirectory}; rm -rf .git)
      fi
    elif [ "${packaging}" = "INSTALLER" ]; then
      echo "Running installer for ${name} ..."
    else
      echo "Unknown packaging type ${packaging}"
      exit
    fi
  fi

  # Now check to see if there is any additional processing required for this tool
  installScript="${toolDirectory}/post-install.sh"
  if [ -f ${installScript} ]; then
    functions="${PROVISIO_ROOT}/config/provisio-functions.bash"
    ${installScript} \
      "${functions}" \
      "${toolProfileYaml}" \
      "${bin}" \
      "${filename}" \
      "${url}" \
      "${version}" \
      "${id}" \
      "${installLocation}" \
      "${os}"
  fi
  )
}

function add_bash() {
  # ----------------------------------------------------------------------------
  # There is no provisio stanza so we'll backup the ${BASH_FILE} and then
  # add a blank line, and append our provisio stanza.
  # ----------------------------------------------------------------------------
  cp ${BASH_FILE} ${BASH_FILE_BACKUP}
  # Just make the formatting readable
  echo ${PROVISIO_START} > ${BASH_FILE}
  echo "source ${BASH_TEMPLATE}" >> ${BASH_FILE}
  echo ${PROVISIO_END} >> ${BASH_FILE}
  cat ${BASH_FILE_BACKUP} >> ${BASH_FILE}
}

function remove_bash() {
  # ----------------------------------------------------------------------------
  # The provisio stanza is present in the ${BASH_FILE} so we'll back up the
  # file, remove the provisio stanza, and then strip the trailing blank lines.
  # ----------------------------------------------------------------------------
  cp ${BASH_FILE} ${BASH_FILE_BACKUP}
  sed "/^${PROVISIO_START}/,/^${PROVISIO_END}/d" ${BASH_FILE} | \
  awk '/^$/ {nlstack=nlstack "\n";next;} {printf "%s",nlstack; nlstack=""; print;}' > tmp
  mv tmp ${BASH_FILE}
}

function provisionToolProfile() {
  profileYamlFile=${1}
  bin=${2}
  os=${3}
  arch=${4}

  eval $(parse_yaml_with_lists $profileYamlFile)
  eval 'tools=(${!'"tools_"'@})'
  for i in "${tools[@]}"
  do
    if echo ${i} | grep -q 'version$'; then
      # This final sed command is to fix the YAML parsing with does "-" --> "_" so we are flipping
      # it back so all our naming works. The YAML parser does this so it can process lists properly.
      tool=`echo ${i} | sed 's/tools_//' | sed 's/_version//' | sed 's/_/-/g'`
      # Extract the version of the tool specified
      version=${!i}
      tool_descriptor=$(tool_descriptor ${tool})
      provisionTool ${profileYamlFile} ${tool_descriptor} ${bin} ${version} ${os} ${arch}
    fi
  done

  # Cleanup random files deposited by various tarballs that are unpacked
  rm -f ${bin}/LICENSE > /dev/null 2>&1
  rm -f ${bin}/README.md > /dev/null 2>&1
}

function installBashTemplate() {
  profileYamlFile=${1}
  bin=${2}
  os=${3}
  arch=${4}

  eval $(parse_yaml_with_lists $profileYamlFile)
  eval 'tools=(${!'"tools_"'@})'
  for i in "${tools[@]}"
  do
    if echo ${i} | grep -q 'version$'; then
      # This final sed command is to fix the YAML parsing with does "-" --> "_" so we are flipping
      # it back so all our naming works. The YAML parser does this so it can process lists properly.
      tool=`echo ${i} | sed 's/tools_//' | sed 's/_version//' | sed 's/_/-/g'`
      toolBashTemplate=$(tool_bash_template ${tool})
      if [ -f ${toolBashTemplate} ]; then
        echo >> ${bashTemplate}
        echo "# Addition from ${toolBashTemplate}" >> ${bashTemplate}
        cat ${toolBashTemplate} >> ${bashTemplate}
      fi
    fi
  done
}

function installToolProfile() {
  # $1 = profile name

  # Checking prerequisites for given os. We take the output of `uname` and
  # lowercase that to find a script to perform any prereqs. So if we're  on
  # a Mac, we'll a `uname` output Darwin so we'll look for `darwin.bash`.
  ${PROVISIO_ROOT}/config/prereqs/$(uname | tr '[:upper:]' '[:lower:]').bash

  profileName=$1
  profileDirectory="${PROVISIO_ROOT}/profiles/${profileName}"
  profileDirectorySymlink="${PROVISIO_ROOT}/.bin/profile"
  profileYaml="${profileDirectory}/profile.yaml"
  # When we are retrieving all the binaries for this profile we store it inside the specific profile
  # so that we can easily switch with a symlink
  bin="${PROVISIO_ROOT}/.bin/${profileName}"
  mkdir -p "${bin}" > /dev/null 2>&1
  profileDirectory=$(dirname ${profileYaml})

  # Symlink for the provisio bin directory
  rm -f "${PROVISIO_ROOT}/.bin/profile" > /dev/null 2>&1
  ln -s "${PROVISIO_ROOT}/.bin/${profileName}" "${PROVISIO_ROOT}/.bin/profile"
  echo ${profileName} > "${PROVISIO_ROOT}/.bin/current"

  # This is duped below because I need a literal ${HOME} in the output file
  bashTemplate=${profileDirectorySymlink}/.init.bash
  provisioBashTemplate=$HOME/.provisio/config/bash-template.txt
  echo "# Addition from ${provisioBashTemplate}" > ${bashTemplate}
  cat ${provisioBashTemplate} >> ${bashTemplate}

  provisionToolProfile ${profileYaml} ${bin}
  installBashTemplate ${profileYaml} ${bin}

  # Inject the init.bash reference in the users bash init file
  BASH_TEMPLATE="\${HOME}/.provisio/.bin/profile/.init.bash"
  BASH_LOGIN=${HOME}/.bash_login
  BASH_PROFILE=${HOME}/.bash_profile
  # This should ultimately be a profile
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  PROVISIO_START="#---- provisio-start ----"
  PROVISIO_END="#---- provisio-end ----"

  if [ -f "${BASH_PROFILE}" ]; then
    BASH_FILE=${BASH_PROFILE}
  elif [ -f "${BASH_LOGIN}" ]; then
    BASH_FILE=${BASH_LOGIN}
  fi

  echo "We are modifying ${BASH_FILE} ..."

  # Setup the backup file
  BASH_FILE_BACKUP=${BASH_FILE}.${TIMESTAMP}

  if grep -q '^#---- provisio-start' ${BASH_FILE}; then
    # We want the provisio stanza to refresh to we'll remove it and add
    # the new one back
    remove_bash
    add_bash
  else
    add_bash
  fi
}
