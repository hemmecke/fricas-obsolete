#! /bin/sh

# This script should be run after a checkout of the src/test
# subdirectory from the repository. It assumes that the autotools
# (autoconf, automake) are installed.

error() {
    echo "$1" && exit 1
}

# Initialize the build system using the GNU AutoTools.
echo "Calling autoreconf ..."
autoreconf -i --verbose -Wall || \
    error "autoreconf could not generate all necessary files."
