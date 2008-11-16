#!/usr/bin/perl

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

open HTML, ">labels.html";
print HTML <<HTML;
<html>

<style type="text/css">
div.column {
	position:	absolute;
	width:	2.05in;
	top:	0.5in;
}
div.column > div {
	width:	1.75in;
	height:	0.5in;
	text-align:	center;
	line-height:	0.5in;
	font-size:	9pt;
}
div#col1 {
	left:	0.3in;
}
div#col2 {
	left:	2.35in;
}
div#col3 {
	left:	4.4in;
}
div#col4 {
	left:	6.45in;
}
</style>

<body>

HTML

my $i = 0;
foreach my $lc (sort lcsort keys %books) {
	printf "%-${longest_lc}s  %s\n",
		$lc, substr($books{$lc}, 0, 80 - $longest_lc - 2);
	if($i < 80) {
		if(($i % 20) == 0) {
			if($i > 0) {
				print HTML <<HTML;
</div>

HTML
			}
			my $col = $i / 20 + 1;
			print HTML <<HTML;
<div class="column" id="col$col">
HTML
		}
		print HTML "<div>$lc</div>\n";
	}

	$i++;
}

print HTML <<HTML;
</div>

</body>
</html>
HTML

close HTML;

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
