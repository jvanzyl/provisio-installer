#!/usr/bin/env bash

# NOTES:
# https://stackoverflow.com/questions/669452/is-double-square-brackets-preferable-over-single-square-brackets-in-ba

## ---------------------------------------------------------------------------------------------------------------------
## YAML parsing and handling
## ---------------------------------------------------------------------------------------------------------------------

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

## ---------------------------------------------------------------------------------------------------------------------
## Artifact retrieval
## ---------------------------------------------------------------------------------------------------------------------
## Given the id, url, and filename of the artifact let's check our cache
## to see if it's present locally first before attempting to download it.
##
## Use an inprogress suffix on the file so if the downloading process is
## interrupted then we can clean up the file and start over if necessary
## ---------------------------------------------------------------------------------------------------------------------
##
## This is primarily for the Adoptium API urls that contain "+" signs in the version.
##
## https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
## ---------------------------------------------------------------------------------------------------------------------

function retrieveArtifact() {
  id="${1}"
  version="${2}"
  url="${3}"
  filename="${4}"

  file="${PROVISIO_CACHE}/${id}/${version}/${filename}"
  fileInProgress="${file}.inprogress"
  parentDirectory=$(dirname ${file})

  if [ ! -f ${file} ]; then
    if [ ! -d ${parentDirectory} ]; then
      mkdir -p ${parentDirectory}
    fi
    if [ -f ${fileInProgress} ]; then
      # An inprogress file is present so remove it and start over.
      rm -rf ${fileInProgress}
    fi
    curl -#L -o ${fileInProgress} ${url}
    mv ${fileInProgress} ${file}
  fi
  echo ${file}
}

## ---------------------------------------------------------------------------------------------------------------------
## Tool provisioning
## ---------------------------------------------------------------------------------------------------------------------

function debug() {
  message=${1}
  [ -n "$PROVISIO_DEBUG_FUNCTIONS" ] && echo ${message}
}

function debugN() {
  message=${1}
  [ -n "$PROVISIO_DEBUG_FUNCTIONS" ] && echo -n ${message}
}

function provisionTool() {

  profileName=${1}
  # The profile being provisioned: ${HOME}/.provisio/profiles/jvanzyl/profile.yaml
  toolProfileYaml=${2}
  # Tool descriptor yaml: ${HOME}/.provisio/tools/jenv/descriptor.yml
  toolConfigurationYaml=${3}
  bin=${4}
  version=${5}

  os=$(uname)
  arch=$(uname -m)

  unset id
  unset name
  unset layout
  unset pathManagedBy
  unset defaultVersion
  unset executable
  unset architecture
  unset namingStyle
  unset packaging
  unset osMappings
  unset archMappings
  unset urlTemplate
  unset darwinUrlTemplate
  unset linuxUrlTemplate
  unset tarSingleFileToExtract
  unset installation

  toolDirectory=$(dirname ${toolConfigurationYaml})
  profileBinaryDirectory="${PROVISIO_ROOT}/.bin/${profileName}"
    # TODO: the .versions files and multiple runtimes are generally not supported right now
  profileVersionsDirectory="${profileBinaryDirectory}/.versions"

  (
    # We are doing everything inside a subshell with the tools directory so that when people
    # write scripts they are relative to the directory with resources that might be referenced
    cd ${toolDirectory}
    eval $(parse_yaml_with_lists ${toolConfigurationYaml})
    executableLocation="${bin}/${executable}"
    installLocation="${bin}/${id}/${version}"

    # Executables are currently all stored in one directory, and installations live in their own directory.
    installedVersion=$(cat ${profileVersionsDirectory}/${id} 2> /dev/null)
    if [ "${layout}" = "file" ]; then
       debugN "Checking if the version (${version}:${installedVersion}) is up-to-date and the executable ${executable} exists here: ${executableLocation} ... "
      if [ "${version}" = "${installedVersion}" -a -f "${executableLocation}" ]; then
        debug "yes, moving on ..."
        return
      else
        rm -f ${executableLocation}
      fi
    elif [ "${layout}" = "directory" ]; then
      debugN "Checking if the version (${version}:${installedVersion}) is up-to-date and the installation ${id} exists here: ${installLocation} ... "
      if [ "${version}" = "${installedVersion}" -a -d "${installLocation}" ]; then
        debug "yes, moving on..."
        return
      else
        # TODO (multiple-rutimes) Temporary hack to allow multiple versions of Java to be installed.
        [ "${id}" != "java" ] && rm -rf ${installLocation}
      fi
    fi
    debug "no, installing ..."

    [ ! -d ${bin} ] && mkdir -p ${bin}

    # Select the OS template is available. Uses the OS name from the system: Darwin, Linux, ...
    if [ "${os}" = "Darwin" -a ! -z "${darwinUrlTemplate}" ]; then
      urlTemplate=${darwinUrlTemplate}
    elif [ "${os}" = "Linux" -a ! -z "${linuxUrlTemplate}" ]; then
      urlTemplate=${linuxUrlTemplate}
    fi

    eval 'osMappings=(${!'"osMappings"'@})'
    for i in "${osMappings[@]}"; do
      # What is returned by $(uname) like Darwin or Linux
      osIdentifier=`echo ${i} | sed 's/osMappings_//'`
      # What the tool uses in its naming like linux os osx
      osIdentifierToolUses=${!i}
      # Transform os identifier
      os=$(echo ${os} | sed -e "s/${osIdentifier}/${osIdentifierToolUses}/")
    done

    eval 'archMappings=(${!'"archMappings_"'@})'
    for i in "${archMappings[@]}"; do
      # What is returned by $(uname -m) like x86_64
      archIdentifier=`echo ${i} | sed 's/archMappings_//'`
      # What the tool uses in its naming like amd64
      archIdentifierToolUses=${!i}
      # Transform arch identifier
      arch=$(echo ${arch} | sed -e "s/${archIdentifier}/${archIdentifierToolUses}/")
    done

    url=$(echo $urlTemplate | \
      sed -e "s@{version}@${version}@g" \
          -e "s@{os}@${os}@g" \
          -e "s@{arch}@${arch}@g")


    # At this point we have the mapped os and arch version, not the original values as returned by uname. We
    # may need to consider keeping the original value and the mapped value for installation scripts.

    # Most of the binaries we have downloaded to date have urls with names of files, but
    # there are APIs for retrieving urls like Eclipse Adoptium where we can't use the
    # basename of the url to glean the file name. We need to use the "filename" response
    # header.
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

        tar xf ${file} ${tarSingleFileToExtract}
        mv ${tarSingleFileToExtract} ${executableLocation}
      else
        if [ ! -z "${layout}" -a "${layout}" = "directory" ]; then
          mkdir -p ${installLocation} > /dev/null 2>&1
          tar xf ${file} ${stripComponents} -C ${installLocation}
        else
          tar xf ${file} ${stripComponents} -C ${bin}
        fi
      fi
    elif [ "${packaging}" = "FILE" ]; then
      file=$(retrieveArtifact ${id} ${version} ${url} ${filename})
      target="${bin}/${executable}"
      cp ${file} ${target}
      chmod +x ${target}
    elif [ "${packaging}" = "ZIP" -o "${packaging}" = "ZIP_JUNK" ]; then
      [ "${packaging}" = "ZIP_JUNK" ] && junk="-j"
      file=$(retrieveArtifact ${id} ${version} ${url} ${filename})
      if [ ! -z "${layout}" -a "${layout}" = "directory" ]; then
        mkdir -p ${installLocation} > /dev/null 2>&1
        unzip ${junk} -q -o ${file} -d ${installLocation}
      else
        unzip ${junk} -q -o ${file} -d ${bin}
      fi
    elif [ "${packaging}" = "INSTALLER" ]; then
      echo "Running installer for ${name} ..."
    else
      echo "Unknown packaging type ${packaging}"
      exit
    fi

    # Now check to see if there is any additional processing required for this tool
    installScript="${toolDirectory}/post-install.sh"
    if [ -f ${installScript} ]; then
      ${installScript} \
        "${PROVISIO_FUNCTIONS}" \
        "${toolProfileYaml}" \
        "${bin}" \
        "${filename}" \
        "${url}" \
        "${version}" \
        "${id}" \
        "${installLocation}" \
        "${os}" \
        "${arch}" \
        "${profileBinaryDirectory}"
    fi
  )
}

## ---------------------------------------------------------------------------------------------------------------------
## Profile provisioning
## ---------------------------------------------------------------------------------------------------------------------
## Provisioning a tool profile places binaries within a directory structure with no modification of the user
## environment or shell initialization scripts. This is generally used to put a set of binaries on a machine for tools
## to use, or to build docker images.
## ---------------------------------------------------------------------------------------------------------------------

function provisionToolProfile() {
  # The profile being provisioned: ${PROVISIO_ROOT}/profiles/jvanzyl/profile.yaml
  profileName=${1}
  profileYamlFile=${2}
  bin=${3}

  echo ${profileName}
  echo ${profileYamlFile}

  profileVersionsDirectory="${PROVISIO_ROOT}/.bin/${profileName}/.versions"
  mkdir -p ${profileVersionsDirectory} > /dev/null 2>&1

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
      tool_descriptor=${PROVISIO_TOOLS}/${tool}/descriptor.yml
      # TODO (multiple-rutimes) Temporary hack to allow multiple versions of Java to be installed.
      version=$(echo ${version} | sed 's/ *//') # Remove any spaces before splitting
      IFS=',' read -ra versions <<< "${version}"
      for v in "${versions[@]}"; do
        provisionTool ${profileName} ${profileYamlFile} ${tool_descriptor} ${bin} ${v}
      done
      # After successful provisioning, record the version of the tool provisioned
      echo -n "${version}" > ${profileVersionsDirectory}/${tool}
    fi
  done

  # Cleanup random files deposited by various tarballs that are unpacked
  rm -f ${bin}/LICENSE > /dev/null 2>&1
  rm -f ${bin}/README.md > /dev/null 2>&1
}

## ---------------------------------------------------------------------------------------------------------------------
## Shell script handing
## ---------------------------------------------------------------------------------------------------------------------

## These are used by the installation and bash functions

## This I think will work in bash and zsh in its form. It's really
## a set of PATH additions and modifications.
BASH_TEMPLATE="\${HOME}/.provisio/.bin/profile/.init.bash"

## BASH
BASH_LOGIN="${HOME}/.bash_login"
BASH_PROFILE="${HOME}/.bash_profile"
SHELL_INIT_FILE=""
SHELL_INIT_FILE_BACKUP=""

## ZSH
ZSH_PROFILE="${HOME}/.zprofile"
ZSH_RC="${HOME}/.zshrc"

PROVISIO_START="#---- provisio-start ----"
PROVISIO_END="#---- provisio-end ----"

function installShellInitializationTemplate() {
  profileDirectorySymlink=${1}
  profileYamlFile=${2}
  profileShellInit=${3}

  provisioBashTemplate=${PROVISIO_TOOLS}/bash-template.txt
  profileBashTemplate=${profileDirectorySymlink}/.init.bash
  echo "## -----------------------------------------------------------------------------" > ${profileBashTemplate}
  echo "## Addition from ${provisioBashTemplate}" >> ${profileBashTemplate}
  cat ${provisioBashTemplate} >> ${profileBashTemplate}

  eval $(parse_yaml_with_lists $profileYamlFile)
  eval 'tools=(${!'"tools_"'@})'
  for i in "${tools[@]}"
  do
    if echo ${i} | grep -q 'version$'; then
      # This final sed command is to fix the YAML parsing with does "-" --> "_" so we are flipping
      # it back so all our naming works. The YAML parser does this so it can process lists properly.
      tool=`echo ${i} | sed 's/tools_//' | sed 's/_version//' | sed 's/_/-/g'`
      version=${!i}
      toolBashTemplate=${PROVISIO_TOOLS}/${tool}/bash-template.txt
      toolConfigurationYaml=${PROVISIO_TOOLS}/${tool}/descriptor.yml
      unset id
      unset name
      unset layout
      unset pathManagedBy
      eval $(parse_yaml_with_lists ${toolConfigurationYaml})
      if [ "${layout}" = "directory" ]; then
        # Everytool with a directory layout has to have its directory inserted into the $PATH. So we need to create an
        # envar that won't conflict with anything else potentially used. Something like the following:
        # PROVISIO_FOO_HOME=${PROVISIO_PROFILE_BIN}/aws-cli/{version}
        # export PATH="${PROVISIO_FOO_HOME}/bin:${PATH}"
        #
        # There are exceptions so if there is a bash-template.txt file then we'll use that, but in most cases
        # we can generate something that works putting the tools bin/ directory on the path.
        if [ -f ${toolBashTemplate} ]; then
          echo >> ${profileBashTemplate}
          echo "## -----------------------------------------------------------------------------" >> ${profileBashTemplate}
          echo "## Addition from ${toolBashTemplate}" >> ${profileBashTemplate}
          echo "## -----------------------------------------------------------------------------" >> ${profileBashTemplate}
          cat ${toolBashTemplate} | sed -e "s/{version}/${version}/" >> ${profileBashTemplate}
        else
          if [ -z "${pathManagedBy}" ]; then
            toolEnvarName=$(echo PROVISIO_${tool} | awk '{ print toupper($0) }')
            echo >> ${profileBashTemplate}
            echo "## -----------------------------------------------------------------------------" >> ${profileBashTemplate}
            echo "## Addition generated by provisio" >> ${profileBashTemplate}
            echo "## -----------------------------------------------------------------------------" >> ${profileBashTemplate}
            # This is super ugly but works and keeps most tools from having to specify a bash-template.txt
            echo "${toolEnvarName}_HOME=\${PROVISIO_PROFILE_BIN}/${tool}/${version}" >> ${profileBashTemplate}
            echo "export PATH=\${${toolEnvarName}_HOME}/bin:\${PATH}" >> ${profileBashTemplate}
          fi
        fi
      fi
    fi
  done

  ## Add the profile specific shell initialization
  if [ -f "${profileShellInit}" ]; then
    echo >> ${profileBashTemplate}
    echo "## -----------------------------------------------------------------------------" >> ${profileBashTemplate}
    echo "## Addition from ${profileShellInit}" >> ${profileBashTemplate}
    echo "## -----------------------------------------------------------------------------" >> ${profileBashTemplate}
    cat ${profileShellInit} >> ${profileBashTemplate}
  fi

  if [ -f "${BASH_PROFILE}" ]; then
    SHELL_INIT_FILE=${BASH_PROFILE}
  elif [ -f "${BASH_LOGIN}" ]; then
    SHELL_INIT_FILE=${BASH_LOGIN}
  elif [ -f "${ZSH_PROFILE}" ]; then
    SHELL_INIT_FILE=${ZSH_PROFILE}
  elif [ -f "${ZSH_RC}" ]; then
    SHELL_INIT_FILE=${ZSH_RC}
  fi

  echo "We are modifying ${SHELL_INIT_FILE} ..."

  # Setup the backup file
  SHELL_INIT_FILE_BACKUP=${SHELL_INIT_FILE}.provisio_backup

  if grep -q "${PROVISIO_START}" ${SHELL_INIT_FILE}; then
    ## We want the provisio stanza to refresh to we'll remove it and add the new one back
    removeProvisioFromShellInitialization
    addProvisioToShellInitialization
  else
    addProvisioToShellInitialization
  fi
}

function addProvisioToShellInitialization() {
  # ----------------------------------------------------------------------------
  # There is no provisio stanza so we'll backup the ${SHELL_INIT_FILE} and then
  # add a blank line, and append our provisio stanza.
  # ----------------------------------------------------------------------------
  cp ${SHELL_INIT_FILE} ${SHELL_INIT_FILE_BACKUP}
  echo ${PROVISIO_START} > ${SHELL_INIT_FILE}
  echo "source ${BASH_TEMPLATE}" >> ${SHELL_INIT_FILE}
  echo ${PROVISIO_END} >> ${SHELL_INIT_FILE}
  cat ${SHELL_INIT_FILE_BACKUP} >> ${SHELL_INIT_FILE}
}

function removeProvisioFromShellInitialization() {
  # ----------------------------------------------------------------------------
  # The provisio stanza is present in the ${SHELL_INIT_FILE} so we'll back up the
  # file, remove the provisio stanza, and then strip the trailing blank lines.
  # ----------------------------------------------------------------------------
  tmpfile=$(mktemp -t provisio.XXXXXX) # Xs are required on linux
  cp ${SHELL_INIT_FILE} ${SHELL_INIT_FILE_BACKUP}
  sed "/^${PROVISIO_START}/,/^${PROVISIO_END}/d" ${SHELL_INIT_FILE} | \
  awk '/^$/ {nlstack=nlstack "\n";next;} {printf "%s",nlstack; nlstack=""; print;}' > ${tmpfile}
  mv ${tmpfile} ${SHELL_INIT_FILE}
}

## ---------------------------------------------------------------------------------------------------------------------
## Profile installation
## ---------------------------------------------------------------------------------------------------------------------
## Installing a tool profile is placing the binaries within a directory structure and modifying the user's
## environment and shell initialization scripts.
## ---------------------------------------------------------------------------------------------------------------------

function installToolProfile() {
  ## $1 = profile name

  ## Checking prerequisites for given os. We take the output of `uname` and
  ## lowercase that to find a script to perform any prereqs. So if we're  on
  ## a Mac, we'll a `uname` output Darwin so we'll look for `darwin.bash`.
  prereqScript="${PROVISIO_LIBEXEC}/$(uname | tr '[:upper:]' '[:lower:]').bash"
  [[ -f ${prereqScript} ]] && ${prereqScript}

  profileName=$1
  ##
  ## We look for profiles in the following places:
  ##
  ## 1) ${PWD}/.provisio/profiles
  ##
  ## 2) ${HOME}/.provisio/profiles
  ##
  if [ -d "${PWD}/.provisio/profiles/${profileName}" ]; then
    profileDirectory="${PWD}/.provisio/profiles/${profileName}"
  elif [ -d "${PROVISIO_ROOT}/profiles/${profileName}" ]; then
   profileDirectory="${PROVISIO_ROOT}/profiles/${profileName}"
  else
    echo "The provisio profile '${profileName}' cannot be found. Exiting."
    exit 1
  fi

  profileDirectorySymlink="${PROVISIO_ROOT}/.bin/profile"
  profileYaml="${profileDirectory}/profile.yaml"
  profileShellInit="${profileDirectory}/profile.shell"

  ## When we are retrieving all the binaries for this profile we store it inside the specific profile
  ## so that we can easily switch with a symlink
  bin="${PROVISIO_ROOT}/.bin/${profileName}"
  mkdir -p "${bin}" > /dev/null 2>&1

  ## Symlink for the provisio bin directory
  rm -f "${PROVISIO_ROOT}/.bin/profile" > /dev/null 2>&1
  ln -s "${PROVISIO_ROOT}/.bin/${profileName}" "${PROVISIO_ROOT}/.bin/profile"
  echo ${profileName} > "${PROVISIO_ROOT}/.bin/current"

  provisionToolProfile ${profileName} ${profileYaml} ${bin}
  installShellInitializationTemplate ${profileDirectorySymlink} ${profileYaml} ${profileShellInit}
}

## ---------------------------------------------------------------------------------------------------------------------
## Testing
## ---------------------------------------------------------------------------------------------------------------------
## Various test utilities
## ---------------------------------------------------------------------------------------------------------------------

function toolVersion() {
  tool=${1}
  currentProfile=$(cat ${PROVISIO_ROOT}/.bin/current)
  toolProfileYaml=${PROVISIO_ROOT}/profiles/${currentProfile}/profile.yaml
  eval $(parse_yaml_with_lists $toolProfileYaml)
  eval 'tools=(${!'"tools_"'@})'
  for i in "${tools[@]}" ; do
    if echo ${i} | grep -q 'version$'; then
      if echo ${i} | grep -q ${1} ; then
        echo ${!i}
      fi
    fi
  done
}

function provisioTests() {
  # The profile being provisioned: ${HOME}/.provisio/profiles/jvanzyl/profile.yaml
  profileName=${1}

  if [ -d "${PWD}/.provisio/profiles/${profileName}" ]; then
    profileDirectory="${PWD}/.provisio/profiles/${profileName}"
  elif [ -d "${PROVISIO_ROOT}/profiles/${profileName}" ]; then
   profileDirectory="${PROVISIO_ROOT}/profiles/${profileName}"
  else
    echo "The provisio profile '${profileName}' cannot be found. Exiting."
    exit 1
  fi
  profileYamlFile="${profileDirectory}/profile.yaml"
  os=$(uname)
  arch=$(uname -m)

  eval $(parse_yaml_with_lists $profileYamlFile)

  # This produces a document we can use for testing tools written in different languages
  eval 'tools=(${!'"tools_"'@})'
  for i in "${tools[@]}"
  do
    if echo ${i} | grep -q 'version$'; then
      # This final sed command is to fix the YAML parsing with does "-" --> "_" so we are flipping
      # it back so all our naming works. The YAML parser does this so it can process lists properly.
      tool=`echo ${i} | sed 's/tools_//' | sed 's/_version//' | sed 's/_/-/g'`
      # Extract the version of the tool specified
      version=${!i}
      tool_descriptor=${PROVISIO_TOOLS}/${tool}/descriptor.yml
      # TODO: generate URL for testing
      #url=$(buildUrl ${tool_descriptor} ${version} ${os} ${arch})
      create_variables $tool_descriptor
      echo "- id: ${tool}"
      echo "  version: ${version}"
      echo "  url: ${urlTemplate}"
    fi
  done
}
