#!/usr/bin/env bash

echo "Checking prerequistes for OSX..."

command -v brew > /dev/null 2>&1
if [[ $? != 0 ]]; then
  echo "Brew is not installed."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# These scripts themselves require realpath and at the very least jenv
# uses realpath as well. You can see what utilities are provided
# by coreutils here:
# 
# http://www.maizure.org/projects/decoded-gnu-coreutils/
brew ls --versions coreutils > /dev/null 2>&1
if [[ $? != 0 ]]; then
  brew install coreutils
fi
