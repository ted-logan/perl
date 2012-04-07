#!/usr/bin/perl

use strict;

use boxes;

my %boxes = boxes::boxes();

my @columns = qw(number contents location label);

my @rows;

push @rows, [ map { ucfirst } @columns ];

foreach my $box (sort {$a <=> $b} keys %boxes) {
	push @rows, [ map { $boxes{$box}->{$_} } @columns ];
}

my @colwidth;

foreach my $row (@rows) {
	for(my $i = 0; $i < @columns; $i++) {
		if(length($row->[$i]) > $colwidth[$i]) {
			$colwidth[$i] = length($row->[$i]);
		}
	}
}

splice @rows, 1, 0, [ map { '-' x $_ } @colwidth ];

foreach my $row (@rows) {
	for(my $i = 0; $i < @columns; $i++) {
		printf "%-*s", $colwidth[$i], $row->[$i];
		if($i + 1 < @columns) {
			print "  ";
		}
	}
	printf "\n";
}
