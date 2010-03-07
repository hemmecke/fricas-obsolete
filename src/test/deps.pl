#!/usr/bin/perl
$f = shift;   # name of pamphlet file
$b = shift;   # without .pamphlet extension
$ext = shift; # extension of $b
if ($b =~ /(.*)\.spad/) {$basename=$1}

open($fh, "$f"); # open file for read
$chunkname="";
while(<$fh>) {
    if ($chunkname eq "") {
        if(/^<<test:(.*)>>=/){$chunkname=$1}
	next;
    }
    if (/^@\s*/){$chunkname=""; next}
    if ($ext eq "spad") {
        if (/^[)]abbrev\s+(category|domain|package)\s+([A-Z0-9]{1,8})\s/) {
	    print "$2.stamp: $chunkname.$basename.log\n"
	}
    } elsif ($ext eq "input") {
        if (/^[)]lib[a-z]*\s+([A-Z0-9]{1,8})/) {
	    print "$chunkname.$b: $1.stamp\n"
	}
    } else {die "Unknown extension '$ext'."}
}
close $fh
