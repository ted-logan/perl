#!/usr/bin/perl

# Formats books in Library Thing into a postscript file for easy printing
#
# Log into Library Thing, then save:
# http://www.librarything.com/export-tab
#
# To print using manual feed on Rygel, use:
# $ lpr -o InputSlot=Tray1_Man <FILE>
#
# To figure out what the accepted options are for an arbitrary printer:
# $ lpoptions -l

use strict;

use Encode;

my %books;
my $longest_lc = 0;

while(<>) {
	$_ = decode("ucs-2", $_);
	my @data = split /\t/;
	if($data[13] && $data[21] =~ /Label Me/) {
		$books{$data[13]} = $data[1];
		if(length($data[13]) > $longest_lc) {
			$longest_lc = length($data[13]);
		}
	}
}

# Write output directly using PostScript. See
# http://jaeger.festing.org/changelog/1290.html for discussion.
#
# Note that the generated PostScript doesn't handle overflow very well.
# Try not to print more than 80 labels at once.
open PS, ">labels.ps"
	or die "Can't write labels.ps: $!\n";

print PS <<PS;
%!PS-Adobe-3.0
%%BoundingBox: 0 0 612 792
%%HiResBoundingBox: 0 0 612 792

/inch {72 mul} def

/hpitch 2.06 inch def
/vpitch 0.50 inch def
/width  1.75 inch def
/height 0.50 inch def
/left   0.28 inch def
/top    0.50 inch def
/cols   4    def
/rows  20    def

% Content to print on labels
/content [
PS

foreach my $lc (sort lcsort keys %books) {
	printf "%-${longest_lc}s  %s\n",
		$lc, substr($books{$lc}, 0, 80 - $longest_lc - 2);
	print PS "(", $lc, ")\n";
}

print PS <<PS;
] def

% Height of the letter page
/pageheight 792 def
/fontsize 11 def

/Times-Roman findfont fontsize scalefont setfont

/i 0 def

0 1 cols 1 sub {
  /x exch def
  0 1 rows 1 sub {
    /y exch def

    gsave
    left x hpitch mul add pageheight top sub y vpitch mul sub translate

    % Write the text itself
    i content length lt {
      0 0 moveto
      content i get
      dup stringwidth pop
      width exch sub 2 div
      height fontsize add 2 neg div
      moveto
      show
    } if

    /i i 1 add def

    grestore
  } for
} for

showpage
PS

close PS;

sub lc_fragment {
	$_[0] =~ /^([A-Z][A-Z]?)([0-9]+)\s*\.?\s*([A-Z0-9\. ]*)$/i;
}

sub lcsort {
	my ($a_let, $a_num, $a_rest) = lc_fragment $a;
	my ($b_let, $b_num, $b_rest) = lc_fragment $b;
	return $a_let cmp $b_let ||
		$a_num <=> $b_num ||
		$a_rest cmp $b_rest;
}
