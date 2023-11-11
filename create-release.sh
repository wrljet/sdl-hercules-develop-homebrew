#!/usr/bin/env bash

# create-release.sh
# Part of https://github.com/wrljet/sdl-hercules-develop-homebrew
# Author:  Bill Lewis  bill@wrljet.com
# Updated: 11 NOV 2023

# To install Homebrew
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
# Will require the GitHub cli Homebrew tap
# See: https://github.com/github/homebrew-gh
#
# brew install gh
#  or
# brew upgrade gh

# Print verbose progress information
opt_verbose=${opt_verbose:-true}

# Prompt the user before each major step is started
opt_prompts=${opt_prompts:-true}

#------------------------------------------------------------------------------
if test "$BASH" == "" || "$BASH" -uc "a=();true \"${a[@]}\"" 2>/dev/null; then
    # Bash 4.4+, Zsh
    # Treat unset variables as an error when substituting
    set -uo pipefail
else
    # Bash 4.3 and older chokes on empty arrays with set -u
    set -o pipefail
fi

# Stop on error
# set -e

# Instructions on updating Bash on macOS Mojave 10.14
# https://itnext.io/upgrading-bash-on-macos-7138bd1066ba

if ((BASH_VERSINFO[0] < 4))
then
    # echo "Bash version < v4"
    :
else
    shopt -s globstar
fi

shopt -s nullglob
shopt -s extglob # Required for MacOS

require(){ hash "$@" || exit 127; }

current_time=$(date "+%Y-%m-%d")

# Find and read in the helper functions

fns_dir="$(dirname "$0")"
fns_file="$fns_dir/helper-fns.sh"

if test -f "$fns_file" ; then
    source "$fns_file"
else
    echo "Helper functions script file not found!"
    exit 1
fi

#-----------------------------------------------------------------------------
if [ "$EUID" -eq 0 ]; then
    echo    # print a new line
    echo "Running this as root is dangerous and can cause misconfiguration issues"
    echo "or damage to your system.  Run as a normal user, and the parts that need"
    echo "it will ask for your sudo password (if required)."
    echo    # print a new line
    echo "For information, see:"
    echo "https://askubuntu.com/questions/16178/why-is-it-bad-to-log-in-as-root"
    echo "https://wiki.debian.org/sudo/"
    echo "https://phoenixnap.com/kb/how-to-create-add-sudo-user-centos"
    echo    # print a new line
    read -p "Hit return to exit" -n 1 -r
    echo    # print a new line
    exit 1
fi

#------------------------------------------------------------------------------
# Are we running from the correct directory?
cpwd=`pwd`
curdir=`basename "$cpwd"`

#if [[ "$curdir"  != "zlinux" ]]; then
#	echo "This script needs to be executed from inside the homebrew-sdl-hercules-develop directory. Please retry."
#	exit 1
#fi

#------------------------------------------------------------------------------
echo "This script will rebuild Hercules and create a new Homebrew formula"

# Remove anything existing installed by Homebrew

verbose_msg # output a newline
status_prompter "Step: Remove anything existing installed by Homebrew:"

echo_and_run "brew uninstall sdl-hercules-develop"
echo_and_run "brew untap wrljet/sdl-hercules-develop"

echo_and_run "brew update"

# xcode-select --version
# pkgutil --pkg-info=com.apple.pkg.CLTools_Executables

#------------------------------------------------------------------------------
# Build latest SDL-Hercules-390

verbose_msg # output a newline
verbose_msg "Step: Building SDL-Hercules-390:"

echo "Currently \"installed\" Hercules: `which hercules`"

mkdir -p build
pushd build

  if confirm "Do you want to rebuild Hercules? [y/N]" ; then
    echo "OK"
    ~/hercules-helper/hercules-buildall.sh -v -p --beeps --homebrew --no-bashrc --config=../build-for-homebrew.conf 
  else
    :
  fi

# Figure out the Hercules version string
  pushd hyperion
    SDL_VERSION=$(./_dynamic_version)
  popd
popd

#------------------------------------------------------------------------------
# Build artifacts are now in /usr/local{bin,lib,share}
# Copy them to ~/sdl-hercules-binaries-macos

verbose_msg # output a newline
status_prompter "Step: Copy build artifacts to local sdl-hercules-binaries-macos repo:"


# Copy SDL-Hercules-390 build artifacts to ~/sdl-hercules-binaries-macos

# /usr/local/bin/
mkdir -p ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckd2ckd   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckd642ckd ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdcdsk   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdcdsk64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdcomp   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdcomp64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckddiag   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckddiag64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdmap    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdswap   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cckdswap64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cfba2fba   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/cfba642fba ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/ckd2cckd   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/ckd2cckd64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/convto64   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdcat    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdconv   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdconv64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdcopy   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdcopy64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdinit   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdinit64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdisup   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdlist   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdload   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdload64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdls     ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdpdsu   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdseq    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dasdser    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/dmap2hrc   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/fba2cfba   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/fba2cfba64 ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/hercifc    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/herclin    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/hercules   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/hetget     ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/hetinit    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/hetmap     ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/hetupd     ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/maketape   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/tapecopy   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/tapemap    ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/tapesplt   ~/sdl-hercules-binaries-macos/bin
cp /usr/local/bin/vmfplc2    ~/sdl-hercules-binaries-macos/bin
# cp /usr/local/bin/voldsext.cmd  ~/sdl-hercules-binaries-macos/bin

# /usr/local/lib/
mkdir -p ~/sdl-hercules-binaries-macos/lib
cp -r /usr/local/lib/hercules              ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhdt3420_not_mod.dylib ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhdt3420_not_mod.la    ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libherc.dylib            ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libherc.la               ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhercd.dylib           ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhercd.la              ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhercs.dylib           ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhercs.la              ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libherct.dylib           ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libherct.la              ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhercu.dylib           ~/sdl-hercules-binaries-macos/lib
cp /usr/local/lib/libhercu.la              ~/sdl-hercules-binaries-macos/lib

# /usr/local/share
mkdir -p ~/sdl-hercules-binaries-macos/share
cp -r /usr/local/share/hercules ~/sdl-hercules-binaries-macos/share

mkdir -p ~/sdl-hercules-binaries-macos/share/man/man1
mkdir -p ~/sdl-hercules-binaries-macos/share/man/man4
cp /usr/local/share/man/man1/cckddiag.1  ~/sdl-hercules-binaries-macos/share/man/man1
cp /usr/local/share/man/man1/dasdseq.1   ~/sdl-hercules-binaries-macos/share/man/man1
cp /usr/local/share/man/man1/vmfplc2.1   ~/sdl-hercules-binaries-macos/share/man/man1
cp /usr/local/share/man/man4/cckd.4      ~/sdl-hercules-binaries-macos/share/man/man4

#------------------------------------------------------------------------------
# Find current/newest tag in the binaries repo

verbose_msg # output a newline
status_prompter "Step: Find current/newest tag already in the binaries repo:"

pushd ~/sdl-hercules-binaries-macos

  git config user.email "bill@wrljet.com"
  git config user.name "Bill Lewis"

  git status
  git commit -a -m "SDL-Hercules-390 build $SDL_VERSION"
  git push

# Ideas in this section taken from https://gist.github.com/chadwagoner-sf/5a344f7e5601646721b5ff232f056113
# Forked from GitHub CSTDev/auto-increment-version.sh

# Ensure main is up-to-date
##git pull origin main --quiet

# Get highest tag number
VERSION=`git describe --abbrev=0 --tags`

# Replace . with space so can split into an array
VERSION_BITS=(${VERSION//./ })

#get number parts and increase last one by 1
VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM1=`echo $VNUM1 | sed 's/v//'`

# Check for #major or #minor in commit message and increment the relevant version number
MAJOR=`git log --format=%B ${VERSION}..HEAD --oneline | grep '#major'`
MINOR=`git log --format=%B ${VERSION}..HEAD --oneline | grep '#minor'`

if [ "$MAJOR" ]; then
    echo "Update major version"
    VNUM1=$((VNUM1+1))
    VNUM2=0
    VNUM3=0
elif [ "$MINOR" ]; then
    echo "Update minor version"
    VNUM2=$((VNUM2+1))
    VNUM3=0
else
    echo "Update patch version"
    VNUM3=$((VNUM3+1))
fi

# Create new tag
NEW_TAG="v$VNUM1.$VNUM2.$VNUM3"

#------------------------------------------------------------------------------
verbose_msg # output a newline
status_prompter "Step: Updating $VERSION to $NEW_TAG and create GitHub release:"

echo "Updating $VERSION to $NEW_TAG"

# Get current hash and see if it already has a tag
GIT_COMMIT=`git rev-parse HEAD`
NEEDS_TAG=`git describe --contains $GIT_COMMIT 2>/dev/null`

# Only tag if no tag already (would be better if the git describe command above could have a silent option)
if [ -z "$NEEDS_TAG" ]; then
    echo "Tagged with $NEW_TAG (Ignoring fatal:cannot describe - this means commit is untagged) "
    echo_and_run "git tag -a $NEW_TAG -m \"SDL-Hercules-390 build $SDL_VERSION\""
    echo_and_run "git push --tags"
    echo_and_run "gh release create $NEW_TAG --generate-notes --prerelease --title \"SDL-Hercules-390 build $SDL_VERSION\""
#    git fetch --all --tags --prune --prune-tags --quiet
else
    echo "Already a tag ($VERSION) on this commit.  Nothing to do."
fi

echo_and_run "popd"

#------------------------------------------------------------------------------
# Create new formula (with new tag)

verbose_msg # output a newline
status_prompter "Step: Create new formula (with new tag $NEW_TAG):"

# Update release tag in URL
echo_and_run "cp sdl-hercules-develop.rb sdl-hercules-develop.rb.old"

gsed -i -e "s/v0\.9\.[0-9]\+\.tar\.gz/$NEW_TAG.tar.gz/" sdl-hercules-develop.rb

# Update formula (download release and get sha256)
echo_and_run "rm /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/sdl-hercules-binaries-macos.rb"

# echo_and_run "brew fetch --formula sdl-hercules-develop.rb --build-from-source"
# echo_and_run "brew fetch --formula sdl-hercules-develop.rb --build-from-source 2>/dev/null | grep -e '^SHA256:\s\+' | awk '{print \$2}'"
SHA256=$(brew fetch --formula sdl-hercules-develop.rb --build-from-source 2>/dev/null | grep -e '^SHA256:\s\+' | awk '{print $2}')
echo "new sha256: $SHA256"

# Displays:
# SHA256: a21951a4fafaac1808ca818a776ff07413bb4cee9d4f19ce4a05565746923346

# Edit the sha256
gsed -i -e "s/  sha256 \"[0-9a-f]\+\"/  sha256 \"$SHA256\"/" sdl-hercules-develop.rb

head sdl-hercules-develop.rb
git status

#------------------------------------------------------------------------------
verbose_msg # output a newline
status_prompter "Step: Commit new Homebrew formula to GitHub (with new tag $NEW_TAG):"

echo_and_run "git add sdl-hercules-develop.rb"
echo_and_run "git commit -m \"Formula $NEW_TAG, SDL-Hercules-390 build $SDL_VERSION\""
echo_and_run "git push"

# end

