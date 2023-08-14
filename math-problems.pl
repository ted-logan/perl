#!/usr/bin/perl

use strict;

my $addition = 0;

for(my $i = 0; $i < 4; $i++) {
	my @a;
	my @b;
	my @c;
	for(my $j = 0; $j < 4; $j++) {
		my ($a, $b, $c);

		do {
			$a = int(rand(1000));
			$b = int(rand(1000));
			$c = $a + $b;
		} while($c >= 1000);

		push @a, $a;
		push @b, $b;
		push @c, $c;
	}

	if($addition) {
		foreach my $a (@a) {
			printf "  %3d    ", $a;
		}
		print "\n";
		foreach my $b (@b) {
			printf "+ %3d    ", $b;
		}
		print "\n";
	} else {
		foreach my $c (@c) {
			printf "  %3d    ", $c;
		}
		print "\n";
		foreach my $a (@a) {
			printf "- %3d    ", $a;
		}
		print "\n";
	}
	foreach my $a (@a) {
		print "  ---    ";
	}
	print "\n";
	print "\n";
}
