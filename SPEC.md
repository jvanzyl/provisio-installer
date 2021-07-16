# Provisio Specification

packaging:
  - TARGZ
  - TARGZ_STRIP
  - FILE
  - ZIP
  - GIT
  - INSTALLER

layout:
  - file: there is just one binary like kubectl, helm, etc. We really only need executable as it implies a file layout
  - directory: there is a directory structure associated with the tool like the AWS CLI, or jEnv

urlTemplate: General URL template
darwinUrlTemplate: OS specific url because there is no general format
linuxUrlTemplate: OS specific url because there is no general format

namingStyle:
  - LOWER
  - CAPITALIZE
  - CUSTOM (usually accompanied by {os}UrlTemplate)

```
---
id: helm
name: Helm
executable: helm
architecture: amd64
namingStyle: LOWER
packaging: TARGZ_STRIP
defaultVersion: v2.16.1
urlTemplate: https://get.helm.sh/helm-{version}-{os}-{arch}.tar.gz
```

## Post install scripts

$1 / ${functions} : reference to provisio bash functions. i can probably source this so it doesn't have to be passed in
$2 / ${profile}   : the profile yaml, we can probably make a standard envar here
$3 / ${bin}       : the profile bin directory, can be likely be replaced with ${PROVISIO_PROFILE_BIN}
$4 / ${file}      : tool file or archive
$5 / ${url}
$6 / ${version}

how to get a descriptor that describes all the commands. it would help with tools like concord, and could automatically generate autocomplete tools
