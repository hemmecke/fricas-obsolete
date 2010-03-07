###################################################################
#
# SPADUNIT
# Copyright (C) 2010,  Ralf Hemmecke <ralf@hemmecke.de>
#
###################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###################################################################
# This is the configure.ac file of the testing framework.
# We don't bother much about finding required programs, since
# we assume that configure will be called from a place where
# all the required programs can be made available through the PATH
# environment variable. We basically do only a sanity check here.
###################################################################
AC_PREREQ(2.61)
AC_INIT(
  [SpadUnit],
  [0.0.1],
  [ralf@hemmecke.de])

# Sanity check
AC_CONFIG_SRCDIR([build-setup.sh])

# Certain configuration files are kept in the config subdirectory.
AC_CONFIG_AUX_DIR(config)
AC_CONFIG_MACRO_DIR(config)

# Init Automake (non-gnu standard)
AM_INIT_AUTOMAKE([-Wall -Werror foreign parallel-tests color-tests])

# Check for existing AXIOMsys
AC_ARG_WITH([axiomsys],
    [AS_HELP_STRING([--with-axiomsys],
                    [specify place of the AXIOMsys executable])],
    # Action if --with-axiomsys is given.
    # We only accept a full path to the executable. Anything else
    # will be an error.
    [if test -x $withval; then
        SPADINTERPRETER=$withval
     else
        AC_MSG_ERROR([--with-axiomsys specified a non-executable program])
     fi],
    # Action if --with-axiomsys is not given.
    # We will start looking in the path.
    [AC_PATH_PROGS([SPADINTERPRETER], [AXIOMsys])
     if test -z "$SPADINTERPRETER" || test ! -x "$SPADINTERPRETER"; then
        AC_MSG_ERROR([Missing AXIOMsys.])
     fi]
)

# We need notangle to get things going. That must be in the PATH.
AC_CHECK_PROGS([NOTANGLE], [notangle])

# We want GNU Make.
AC_CHECK_PROGS([MAKE], [gmake make])
if ! $MAKE --version | grep 'GNU Make' 2> /dev/null; then
   AC_MSG_ERROR([Need GNU Make to continue])
fi

# The Makefiles
AC_CONFIG_FILES([Makefile])

# Output everything
AC_OUTPUT
