#!/usr/bin/perl
# Transform output of FriCAS with )set output tex on into a .tex file
# where everything outside \begin{LaTeXMath}...\end{LaTeXMath} is
# typeset in an verbatim environment.
print <<'EOF';
\documentclass{article}
\usepackage{fricasmath}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\usepackage{color}
\makeatletter
\def\MakeFramed{\begingroup}
\def\endMakeFramed{\endgroup}%
\IfFileExists{framed.sty}{%
  \usepackage{framed}[2003/07/21 v 0.8a]%
}{%
  \PackageWarning{fricas.sty}{framed.sty not found}%
}
\newenvironment{ColoredBackground}[1]%
  {\@ifundefined{background#1}%
     {\def\FrameCommand{}}%
     {\def\FrameCommand{\csname background#1\endcsname}}%
   \trivlist\item\MakeFramed{}}%
  {\endMakeFramed\endtrivlist}
\def\backgroundColor#1#2#{\background@Color{#1}{#2}}
\def\background@Color#1#2#3{%
  \expandafter\gdef\csname background#1\endcsname{\@backgroundColor{#1}#2{#3}}}
\def\@backgroundColor#1{\colorbox}%
\backgroundColor{bgmathoutput}[rgb]{0.95,0.95,1} % (gray)   spad output
\backgroundColor{bgmathinput}[rgb]{0.95,1,0.95}  % (green)  spad output
\newenvironment{TeXOutput}%
  {\begin{ColoredBackground}{bgmathoutput}\small}%
  {\end{ColoredBackground}}
\newenvironment{TeXInput}%
  {\begin{ColoredBackground}{bgmathinput}\small}%
  {\end{ColoredBackground}}
\makeatother
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\begin{document}
\begin{verbatim}
EOF

# Skip compilation output.
while(<>) {if (/-- COMPILATION COMPLETED --/) {last;}}

# Embelish the test stuff with appropriate environments.
while(<>) {
    if(/^\\begin{fricasmath}/) {
        print "\\end{verbatim}\n";
        print "\\begin{TeXOutput}\n";
        print;
    } elsif(/^\\end{fricasmath}/) {
        print;
        print "\\end{TeXOutput}\n";
        print "\\begin{verbatim}\n";
    } elsif(/^e[ (]/) {
        print "\\end{verbatim}\n";
        print "\\begin{TeXInput}\n";
        print "\\begin{verbatim}\n";
        print;
        print "\\end{verbatim}\n";
        print "\\end{TeXInput}\n";
        print "\\begin{verbatim}\n";
    } else {
        print;
    }
}

print <<'EOF';
\end{verbatim}
\end{document}
EOF
