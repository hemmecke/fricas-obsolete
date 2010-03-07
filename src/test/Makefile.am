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
# This is the main Makefile of the testing framework.
# Nothing will be installed via 'make install'.
###################################################################

# This target will only be built during "make check".
# TODO: Take care of what will got into the distribution tarball.
check_DATA = SPADUNIT.stamp

# Just a convenience to have another name.
SPADCOMPILER = $(SPADINTERPRETER)

# Define the TESTS variable.
include tests.mk

# Define the XFAIL_TESTS variable.
include xfailtests.mk

# Build rules for the testfiles from their respective sources.
include deps.mk


TEST_EXTENSIONS = .input .spad
INPUT_LOG_COMPILER = ./call-interpreter
SPAD_LOG_COMPILER = ./call-spadcompiler
check_SCRIPTS = call-interpreter call-spadcompiler

# $1 will be the name of the input file to pipe through AXIOMsys
call-interpreter:
	echo '#!/bin/sh' > $@
	echo 'echo ")read $$1" | $(SPADINTERPRETER)' >> $@
	chmod +x $@

call-spadcompiler:
	echo '#!/bin/sh' > $@
	echo '(echo ")set breakmode quit"; echo ")compile $$1") | $(SPADCOMPILER)' >> $@
	chmod +x $@

# We have to give rules how the generate the respective files for each
# of the TEST_EXTENSIONS. Since the 'setUp' and 'tearDown' chunks can
# be missing, we ignore an error.
.SECONDARY: $(TESTS) # don't delete intermediate .input files
define do-input
echo ")set breakmode quit" > $@
echo ")library SPADZERO" >> $@
echo ")library SPADUNIT" >> $@
-$(NOTANGLE) -RsetUp $< >> $@ 2>/dev/null
$(NOTANGLE) -R"test:$*" $< >> $@
-$(NOTANGLE) -RtearDown $< >> $@ 2>/dev/null
endef

define do-spad
-$(NOTANGLE) -RsetUp $< > $@ 2>/dev/null
$(NOTANGLE) -R"test:$*" $< >> $@
-$(NOTANGLE) -RtearDown $< >> $@ 2>/dev/null
endef

# Make sure generated files are removed via 'make clean'.
# Also remove test related files.
CLEANFILES = \
  $(check_SCRIPTS) \
  $(TEST_EXTENSIONS:%=*%) \
  *.stamp \
  libdb.text \
  *~

CLEANDIRS = SPADZERO.* SPADUNIT.*

clean-local:
	test -z "$(CLEANDIRS)" || rm -rf $(CLEANDIRS)

###################################################################
# We need to provide the testing environment, i.e., assertTrue,
# assertFalse, assertEquals, assertNotEquals.
spadunit.spad: spadunit.spad.pamphlet
	$(NOTANGLE) $< > $@

# Checking the index.KAF file is probably not really OK, but it saves
# us the trouble of finding out what file extension the lisp used by
# AXIOMsys will produce.
SPADUNIT.NRLIB/index.KAF: spadunit.spad
	echo -e ')set breakmode quit\n)compile $<' | $(SPADCOMPILER)

SPADUNIT.stamp: SPADUNIT.NRLIB/index.KAF
	touch $@

###################################################################
# The code below is irrelevant in Makefile.in and Makefile, since it
# is only here as a convenience to generated tests.mk, xfailtests.mk,
# and deps.mk. If tests.mk and deps.mk are maintained differently,
# this code below can be removed.
###################################################################
# Generate deps.mk, tests.mk, and xfailtests.mk by executing
#   make -sf Makefile.am mk
# These generated files are included into the Makefile.am and
# are relevant for which tests are executed.
TEST_EXTS = $(TEST_EXTENSIONS:.%=%)
MKFILES = deps.mk tests.mk xfailtests.mk
mk: $(MKFILES)

# This is the line that for each test goes into tests.mk.
# Here we determine the content of the TESTS variable from all the
# <<test:TESTNAME>>= and <<test-fail>>= lines in the pamphlet file.
define tests-mk
awk -v b=$$b '/^<<test:/{gsub(/<<test:|>>=/,"");printf "\\\n" $$0 "." b}' $$f >> $@
endef

# This is the line that for each test that is expected to fail
# goes into xfailtests.mk.
# Here we determine the content of the XFAIL_TESTS variable from all the
# <<test-fail:TESTNAME>>= lines in the pamphlet file.
define xfailtests-mk
awk -v b=$$b '/^<<test:fail-/{gsub(/<<test:|>>=/,"");printf "\\\n" $$0 "." b}' $$f >> $@
endef

# Generate dependency lines for each test. Make sure the file depends
# on the corresponding .pamphlet source file.
# We assume that for each entry in TEST_EXTENSIONS there is a corresponding
# definition of a do-EXTENSION macro (see, for example, do-input).
define deps-mk
echo "%.$$b: $$f;" '$$(do-'"$$ext"')' >> $@ && perl deps.pl $$f $$b $$ext >> $@
endef

# Do the actual generation of deps.mk and tests.mk.
$(MKFILES): %.mk: Makefile.am $(wildcard $(TEST_EXTS:%=*.%.pamphlet))
	echo "# This is autogenerated by 'make -f Makefile.am $@'" > $@
	if test "tests.mk" = "$@"; then \
	  printf "TESTS = " >> $@; \
	elif test "xfailtests.mk" = "$@"; then \
	  printf "XFAIL_TESTS = " >> $@; \
	fi
	for ext in $(TEST_EXTS); do \
	  for f in $$(ls *.$$ext.pamphlet); do \
	    if test Makefile.am != "$$f"; then \
	      b=`basename $$f .pamphlet`; \
	      $($*-mk); \
	    fi; \
	  done; \
	done
	echo >> $@
