# TODO

- for installs add symlink support to generate symlinks into the bin directory
- how to handle jvms
- start the java implementation we have the start in ck8s
- add general mapping feature of uname (os) and uname -a (arch) support. the os and arch mapping is too complicated
- refactor "packaging" to installationType: TARGZ, FILE and installationType of INSTALLER is really SCRIPT as we just need a catch all way to run
x add caching of binaries for faster development, testing and making new profiles
- add mvnd support
- jenv-init doesn't obey $JENV_ROOT it still puts things in ~/.jenv
- add resume download support with curl: https://stackoverflow.com/questions/19728930/how-to-resume-interrupted-download-automatically-in-curl
- clean up post-install.sh scripts, just pass in everything required instead of having to source functions again
- jenv contaminates the home directory in ~/.jenv, it should be contained within the profile
- there needs to be quite a few tests before letting people contribute
- easy way to keep track of OS differences for paths, like the JDK path on mac vs linux
- keep track of runtimes like JDKs, Go and keep them in separate places
- versions in N dimensions like java8/java11 19/20 for graal and JDKs
- add terraform rc file like in the concord agent image
- bash and fish completion, borrow from jenv
- look at https://github.com/jasperes/bash-yaml/blob/master/script/yaml.sh
- add kubeseal for sealed-secrets
- install go SDK
- add disable flag for tools
- support simple configuration files like for gnupg which won't work without them
- make this work with zsh
x install scripts need to have access to the url so it can directly download if necessary. the gnugp and awscli have hardcoded urls in the scripts
a script to do anything required to install
- allow config of jenv plugins to install (the export and maven plugin are required for the Maven Wrapper to work)
- find latest releases of binaries:
  - curl --silent "https://github.com/helm/helm/releases/latest" | sed 's#.*tag/\(.*\)\".*#\1#'
  - https://github.com/dvershinin/lastversion
  - https://gist.github.com/steinwaywhw/a4cd19cda655b8249d908261a62687f8
- how to get checksums for the binaries so they can be verified
- unit tests for osx and linux
- atomically move the bin/ into place after successfully building a profile
- verify checksums of tools we download to prevent errors
- have versions of profiles and activate specific versions of profiles
- symlink to specific versions of binaries to have a shared repository of binaries almost -- like a maven repo
- add adoptopenjdk support
- add azul jdk support
- idempotency / upgrading
- house multiple versions and create a jenv like mechanism for all flavors
- how to isolate tools that install outside of the PROVISIO_ROOT like jenv and krew
- see if KREW_ROOT will allow be to localize krew to the install root
- look at using graal/picocli for the base code
x the generated init.bash should not go in profile directory
x show the current profile
x switch the current profile
x post-install.sh scripts
x add jenv support
x need a way to parameterize "installs" directories
x prevent re-downlaods of installations (google cloud sdk)
x put provisio-bash.sh in provisio-functions.bash
x keep track of the version of the tool downloaded so that if the version changes in the profile the new version is downloaded

Okta, Concord and Krew represent extensions and work slightly differently so we probably want a way to create a custom script to get each of these to work.

- For Krew we need to install a set of plugins and create some symlinks
- For Okta we need to install some JARs and copy over a profile
