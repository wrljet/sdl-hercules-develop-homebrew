#!/usr/bin/env bash

# create-release.sh
# Part of https://github.com/wrljet/sdl-hercules-develop-homebrew
# Author:  Bill Lewis  bill@wrljet.com
# Updated: 22 NOV 2023

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
set -e

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

#-----------------------------------------------------------------------------
#
# Check for GitHub cli 'gh'
#
    which -s gh
    if [[ $? != 0 ]] ; then
        echo "    GitHub cli 'gh' is not installed"
        exit 1
    fi

#-----------------------------------------------------------------------------

# Normally, if sudo requires a password, it will read it from the user's terminal.
# If the -A (askpass) option is specified, a (possibly graphical) helper program
# is executed to read the user's password and output the password to the standard
# output.  If the SUDO_ASKPASS environment variable is set, it specifies the path
# to the helper program.  Otherwise, if sudo.conf(5) contains a line specifying
# the askpass program, that value will be used.  For example:
# 
#   # Path to askpass helper program
#   Path askpass /usr/X11R6/bin/ssh-askpass

# If no askpass program is available, sudo will exit with an error.

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR="$(dirname $SCRIPT_PATH)"
echo "SCRIPT_DIR= $SCRIPT_DIR"
export SUDO_ASKPASS="$SCRIPT_DIR/askpass.sh"
echo $SUDO_ASKPASS

#------------------------------------------------------------------------------
# Are we running from the correct directory?
cpwd=`pwd`
curdir=`basename "$cpwd"`

#if [[ "$curdir"  != "zlinux" ]]; then
#       echo "This script needs to be executed from inside the homebrew-sdl-hercules-develop directory. Please retry."
#       exit 1
#fi

#------------------------------------------------------------------------------
echo "This script will rebuild Hercules and create a new Homebrew formula"

# Remove anything existing installed by Homebrew

verbose_msg # output a newline
status_prompter "Step: Remove anything existing installed by Homebrew:"

echo_and_run "brew uninstall sdl-hercules-develop || true"
echo_and_run "brew untap wrljet/sdl-hercules-develop || true"

echo_and_run "brew update"

# xcode-select --version
# pkgutil --pkg-info=com.apple.pkg.CLTools_Executables

#------------------------------------------------------------------------------
#
# Build latest SDL-Hercules-390
#
verbose_msg # output a newline
verbose_msg "Step: Building SDL-Hercules-390:"

echo "Currently \"installed\" Hercules: `which hercules`"

echo_and_run "mkdir -p work"
echo_and_run "pushd work >/dev/null"

  if confirm "Do you want to rebuild Hercules? [y/N]" ; then
    echo "OK"
    MACOSX_DEPLOYMENT_TARGET=11.6 ~/hercules-helper/hercules-buildall.sh -v --homebrew --no-bashrc --askpass --config=../build-for-homebrew.conf 
  else
    :
  fi

# Figure out the Hercules version string
  echo_and_run "pushd hyperion >/dev/null"

    SDL_VERSION=$(./_dynamic_version)
    #
    # Remove double quotes and spaces from Fish's version string
    SDL_VERSION="${SDL_VERSION%\"}"
    SDL_VERSION="${SDL_VERSION#\"}"
    SDL_VERSION="${SDL_VERSION//[[:space:]]/}"
    echo "SDL_VERSION: $SDL_VERSION"

  echo_and_run "popd >/dev/null"
  echo "pwd: $(pwd)"
echo_and_run "popd >/dev/null"
echo "pwd: $(pwd)"

#------------------------------------------------------------------------------
#
# Build artifacts are now in /usr/local{bin,lib,share}
# Copy them to ~/sdl-hercules-binaries-macos
#
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
#
# Find current/newest tag in the binaries repo
#
verbose_msg # output a newline
status_prompter "Step: Find current/newest tag already in the binaries repo:"

echo_and_run "pushd ~/sdl-hercules-binaries-macos >/dev/null"

    cat <<FOE >"VERSION"
#
# This file was created by $0, on $(date)
#
# This is version SDL-Hercules-390 build $SDL_VERSION"
#
FOE

  git config user.email "bill@wrljet.com"
  git config user.name "Bill Lewis"

##   # git status
##   # git commit -a -m "SDL-Hercules-390 build $SDL_VERSION"
##   # git push
## 
## # Ideas in this section taken from https://gist.github.com/chadwagoner-sf/5a344f7e5601646721b5ff232f056113
## # Forked from GitHub CSTDev/auto-increment-version.sh
## 
## # Ensure main is up-to-date
## ##git pull origin main --quiet
## 
## # Get highest current tag number
## VERSION=$(git describe --abbrev=0 --tags)
## echo "gti describe --abbrev=0 --tags:=$VERSION"
## 
## echo "Old Version: $VERSION"
## 
## # Replace . with space so can split into an array
## VERSION_BITS=(${VERSION//./ })
## 
## #get number parts and increase last one by 1
## VNUM1=${VERSION_BITS[0]}
## VNUM2=${VERSION_BITS[1]}
## VNUM3=${VERSION_BITS[2]}
## VNUM1=$(echo $VNUM1 | sed 's/v//')
## 
## # Check for #major or #minor in commit message and increment the relevant version number
## MAJOR=$(git log --format=%B ${VERSION}..HEAD --oneline | grep '#major' || true)
## MINOR=$(git log --format=%B ${VERSION}..HEAD --oneline | grep '#minor' || true)
## 
## if [ "$MAJOR" ]; then
##     echo "Update major version"
##     VNUM1=$((VNUM1+1))
##     VNUM2=0
##     VNUM3=0
## elif [ "$MINOR" ]; then
##     echo "Update minor version"
##     VNUM2=$((VNUM2+1))
##     VNUM3=0
## else
##     echo "Update patch version"
##     VNUM3=$((VNUM3+1))
## fi
## 
## # Create new tag
## NEW_TAG="v$VNUM1.$VNUM2.$VNUM3"
## 
## # We want to keep the two most recent release
## # So figure out the tags for two older than that
## 
## DEL_TAG1="v$VNUM1.$VNUM2.$((VNUM3-3))"
## DEL_TAG2="v$VNUM1.$VNUM2.$((VNUM3-4))"
## DEL_TAG3="v$VNUM1.$VNUM2.$((VNUM3-5))"
## 
## 
##     declare -a releases_to_remove=( \
##         "v$VNUM1.$VNUM2.$((VNUM3-3))"  \
##         "v$VNUM1.$VNUM2.$((VNUM3-4))"  \
##         "v$VNUM1.$VNUM2.$((VNUM3-5))"
##     )
## 
##     echo "We want to remove older releases:"
##     for release_tag in "${releases_to_remove[@]}"; do
##         echo "  $release_tag"
##     done
## 
##     for release_tag in "${releases_to_remove[@]}"; do
##         echo "gh release view $release_tag"
##         RC=$(gh release view $release_tag 2>&1 || true)
##         if [[ $RC == "release not found" ]] ; then
##             echo "    No such release: $release_tag"
##         else
##             echo "    Release: $release_tag will be removed"
## 
##             gh release delete $release_tag --cleanup-tag --yes
## echo "gh release return code: $?"
##         fi
##     done

#------------------------------------------------------------------------------
#
# Update $VERSION to $NEW_TAG and create GitHub release
#
verbose_msg # output a newline
## status_prompter "Step: Updating $VERSION to $NEW_TAG and create GitHub release:"

# Trimming older releases...
#
# Show a list of all releases:
#  gh release list
#
# List info about a release:
#  gh release view v0.9.1
# Set return code 0 if the release exists, or 1 if not found
#
# Delete an existing release:
#  gh release delete v0.9.1 --cleanup-tag --yes

## echo "Updating $VERSION to $NEW_TAG"
## 
## # Get current hash and see if it already has a tag
## GIT_COMMIT=$(git rev-parse HEAD || true)
## echo "GIT_COMMIT=$GIT_COMMIT"
## NEEDS_TAG=$(git describe --contains $GIT_COMMIT 2>/dev/null || true)
## echo "NEEDS_TAG=$NEEDS_TAG"
## 
## # Only tag if no tag already (would be better if the git describe command above could have a silent option)
## if [ -z "$NEEDS_TAG" ]; then
##     echo "Tagged with $NEW_TAG (Ignoring fatal:cannot describe - this means commit is untagged) "
##     echo_and_run "git tag -a $NEW_TAG -m \"SDL-Hercules-390 build $SDL_VERSION\""
##     echo_and_run "git push --tags"
##     echo_and_run "gh release create $NEW_TAG --generate-notes --prerelease --title \"SDL-Hercules-390 build $SDL_VERSION\""
## #    git fetch --all --tags --prune --prune-tags --quiet
## else
##     echo "Already a tag ($VERSION) on this commit.  Nothing to do."
## fi

echo_and_run "popd >/dev/null"
echo "pwd: $(pwd)"

#------------------------------------------------------------------------------
#
# Get highest current tag number
VERSION=$(git describe --abbrev=0 --tags)
echo "gti describe --abbrev=0 --tags:=$VERSION"

echo "Old Version: $VERSION"

# Replace . with space so can split into an array
VERSION_BITS=(${VERSION//./ })

#get number parts and increase last one by 1
VNUM1=${VERSION_BITS[0]}
VNUM2=${VERSION_BITS[1]}
VNUM3=${VERSION_BITS[2]}
VNUM1=$(echo $VNUM1 | sed 's/v//')

# Check for #major or #minor in commit message and increment the relevant version number
MAJOR=$(git log --format=%B ${VERSION}..HEAD --oneline | grep '#major' || true)
MINOR=$(git log --format=%B ${VERSION}..HEAD --oneline | grep '#minor' || true)

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

# Make up the binaries tarball
PWD=$(pwd)
pushd ~
# Dir name inside binaries tarball
# e.g. sdl-hercules-binaries-macOS-0.9.26/
rm -rf ~/sdl-hercules-binaries-macOS-$NEW_TAG/
cp -R ~/sdl-hercules-binaries-macOS/ sdl-hercules-binaries-macOS-$NEW_TAG/

echo_and_run "rm -rf sdl-hercules-binaries-macOS-$NEW_TAG/.git"
echo_and_run "tar cfz $PWD/sdl-hercules-binaries-macOS-$SDL_VERSION-$NEW_TAG.tar.gz sdl-hercules-binaries-macOS-$NEW_TAG/"

echo "FIXME FIXME"
echo_and_run "ls -lh $PWD"
echo "FIXME FIXME"

popd

#------------------------------------------------------------------------------
#
# Create new formula (with new tag)
#
verbose_msg # output a newline
status_prompter "Step: Create new formula (with new tag $NEW_TAG):"

# Update release tag in URL
echo_and_run "cp sdl-hercules-develop.rb sdl-hercules-develop.rb.old"

# URL to binaries tarball is of this form:
# https://github.com/wrljet/sdl-hercules-develop-homebrew/releases/download/v0.9.43/sdl-hercules-binaries-macos-4.6.0.10941-SDL-g65c97fd6-v0.9.43.tar.gz

gsed -i -e "s/v0\.9\.[0-9]\+/$NEW_TAG/g" sdl-hercules-develop.rb
#gsed -i -e "s/v0\.9\.[0-9]\+\.tar\.gz/$NEW_TAG.tar.gz/" sdl-hercules-develop.rb

# Update formula (download release and get sha256)
echo_and_run "rm -f /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/sdl-hercules-binaries-macOS.rb"

# echo_and_run "brew fetch --formula sdl-hercules-develop.rb --build-from-source"
# echo_and_run "brew fetch --formula sdl-hercules-develop.rb --build-from-source 2>/dev/null | grep -e '^SHA256:\s\+' | awk '{print \$2}'"

#------------------------------------------------------------------------------
#
# Commit new Homebrew formula to GitHub
#
verbose_msg # output a newline
status_prompter "Step: Commit new Homebrew formula to GitHub (with new tag $NEW_TAG):"

ARTIFACT="sdl-hercules-$SDL_VERSION-macOS.rb"

echo_and_run "git add sdl-hercules-develop.rb"

echo_and_run "git commit -m \"Formula $NEW_TAG, SDL-Hercules-390 build $SDL_VERSION\""
echo_and_run "git push"

#------------------------------------------------------------------------------
#
# Create new .rb release
#
verbose_msg # output a newline
status_prompter "Step: Create new .rb release:"

# Get current hash and see if it already has a tag
GIT_COMMIT=$(git rev-parse HEAD || true)
echo "GIT_COMMIT=$GIT_COMMIT"
NEEDS_TAG=$(git describe --contains $GIT_COMMIT 2>/dev/null || true)
echo "NEEDS_TAG=$NEEDS_TAG"

# Only tag if no tag already (would be better if the git describe command above could have a silent option)
if [ -z "$NEEDS_TAG" ]; then
    echo "Tagged with $NEW_TAG (Ignoring fatal:cannot describe - this means commit is untagged) "
    echo_and_run "git tag -a $NEW_TAG -m \"SDL-Hercules-390 build $SDL_VERSION\""
    echo_and_run "git push --tags"

    echo_and_run "gh release create $NEW_TAG --generate-notes --prerelease --title \"SDL-Hercules-390 build $SDL_VERSION\""

echo_and_run "cp ~/sdl-hercules-binaries-macOS-$SDL_VERSION-$NEW_TAG.tar.gz ."
    echo_and_run "gh release upload $NEW_TAG sdl-hercules-binaries-macOS-$SDL_VERSION-$NEW_TAG.tar.gz"
else
    echo "Already a tag ($VERSION) on this commit.  Nothing to do."
    echo "FIXME FIXME FIXME"
fi

#------------------------------------------------------------------------------
#

# Displays:
# SHA256: a21951a4fafaac1808ca818a776ff07413bb4cee9d4f19ce4a05565746923346
# SHA256=$(brew fetch --formula sdl-hercules-develop.rb --build-from-source 2>/dev/null | grep -e '^SHA256:\s\+' | awk '{print $2}')

SHA256=$(sha256sum sdl-hercules-binaries-macOS-$SDL_VERSION-$NEW_TAG.tar.gz)
echo "New sha256: $SHA256"

# Edit the sha256
gsed -i -e "s/  sha256 \"[0-9a-f]\+\"/  sha256 \"$SHA256\"/" sdl-hercules-develop.rb

head sdl-hercules-develop.rb
git status

#------------------------------------------------------------------------------
#
# Update new .rb release
#
verbose_msg # output a newline
status_prompter "Step: Update new .rb release:"

echo_and_run "cp sdl-hercules-develop.rb $ARTIFACT"
echo_and_run "gh release upload $NEW_TAG $ARTIFACT"

#------------------------------------------------------------------------------
#
# Remove build artifacts
#
echo "Remove build artifacts"
echo_and_run "rm ~/sdl-hercules-binaries-macOS-$SDL_VERSION-$NEW_TAG.tar.gz"
echo_and_run "rm sdl-hercules-binaries-macOS-$SDL_VERSION-$NEW_TAG.tar.gz"
echo_and_run "rm -r ~/sdl-hercules-binaries-macOS-$NEW_TAG/"

#------------------------------------------------------------------------------
#
# Remove old releases
#
verbose_msg # output a newline
status_prompter "Step: Remove older releases:"

# We want to keep the four most recent release
# So figure out the tags for four older than that

DEL_TAG1="v$VNUM1.$VNUM2.$((VNUM3-5))"
DEL_TAG2="v$VNUM1.$VNUM2.$((VNUM3-6))"
DEL_TAG3="v$VNUM1.$VNUM2.$((VNUM3-7))"
DEL_TAG4="v$VNUM1.$VNUM2.$((VNUM3-8))"

    declare -a releases_to_remove=( \
        $DEL_TAG1 \
        $DEL_TAG2 \
        $DEL_TAG3 \
        $DEL_TAG4
    )

    echo "Remove older releases:"
    for release_tag in "${releases_to_remove[@]}"; do
        echo "  $release_tag"
    done

    for release_tag in "${releases_to_remove[@]}"; do
        echo "gh release view $release_tag"
        RC=$(gh release view $release_tag 2>&1 || true)
        if [[ $RC == "release not found" ]] ; then
            echo "    No such release: $release_tag"
        else
            echo "    Release: $release_tag will be removed"

            gh release delete $release_tag --cleanup-tag --yes
        fi
    done

#------------------------------------------------------------------------------
#
# Test install / remove
#
verbose_msg # output a newline
status_prompter "Step: Remove Hercules installed by the build process:"

echo_and_run "pushd work/hyperion/build >/dev/null"
echo_and_run "sudo -A make uninstall"
echo_and_run "popd >/dev/null"
echo "pwd: $(pwd)"

# brew install sdl-hercules-develop.rb
# which hercules
# hercules --version
# brew remove sdl-hercules-develop
# which hercules

# rm /Users/bill/Library/Caches/Homebrew/downloads/9503f4604d3cf6ae7b3711056827504e8627088bae49bb4125cf7bfc4247e6d9--sdl-hercules-binaries-macOS-0.9.6.tar.gz

rm -f /Users/bill/Library/Caches/Homebrew/downloads/*sdl-hercules*

#
# end

