#!/usr/bin/awk
###################################################################
#
# Copyright (C) 2012, 2014, 2015  Ralf Hemmecke <ralf@hemmecke.org>
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
#
# Usage:
#     awk -f src/doc/literatedoc.awk file.spad > file.tex
#     TEXINPUTS=src/doc/:$TEXINPUTS pdflatex file.tex
#
# It is assumed that file.spad is nearly a LaTeX file.
# There should be
#   )if LiterateDoc
# and
#   )endif
# around the LaTeX part.
# To turn the .spad file into a .tex file, one basically has to replace
# ")if LiterateDoc" by "\end{spadcode}" and ")endif" by "\begin{spadcode}".
#
# The following awk code does exactly that. For simplicity, every line
# before the first ")if LiterateDoc" is copied to the output, but with
# a percent sign in front of it.
#
# Furthermore, empty lines after ")endif" and empty lines before
# ")if LiterateDoc" are moved from the code into the documentation part.
#
# The LaTeX part is supposed to contain a line
#   \usepackage{literatedoc}
# which defines a spadcode and verbcode environment.
#
###################################################################

/^[ \t]*$/ {
    if (open_literal) {
        print
    } else {
        emptyline++
    }
    next
}

/^)if LiterateDoc/ {
    if (open_code) {
        print "\\end{spadcode}";
        open_code=0 # non-code section
    }
    while (emptyline>0) {print ""; emptyline--}
    open_literal=1 # LiterateDoc is active
    literate=1 # We have seen at least one ')if LiterateDoc'.
    next
}

/^)endif/ {
    if (!open_literal) {
        print;
        open_code=1 # non-empty spad line seen
    }
    open_literal=0
    next
}

open_literal {print; next}

open_code==0 { # We know this is not an empty line.
    #-- If there is some stuff before the first ')if LiterateDoc', it
    #-- is considered and treated as comments.
    if (!literate) {print "%" $0; next}

    # Print pending empty lines.
    while (emptyline>0) {print ""; emptyline--}
    print "\\begin{spadcode}"
    open_code=1
    print
    next
}

# Arriving here we have open_code==1 and open_literal==0.
{
    while (emptyline>0) {print ""; emptyline--}
    print
}
