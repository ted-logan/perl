#!/usr/bin/perl

use strict;

use POSIX qw(strftime);
use Data::Dumper;

my $boxdir = '/home/jaeger/boxes';

my %boxes = do {
	my %boxes;

	opendir BOXES, $boxdir
		or die "Can't open $boxdir: $!\n";
	foreach my $box (grep /\.txt$/, grep {-f "$boxdir/$_"} readdir BOXES) {
		my ($boxnum) = $box =~ /(\w+)\.txt/;
		my %box = (
			number => $boxnum,
			packed => strftime("%Y-%m-%d %H:%M", localtime((stat "$boxdir/$box")[9]) ),
		);


		open BOX, "$boxdir/$box"
			or die "Can't open $box: $!\n";
		my @contents = <BOX>;
		close BOX;

		my %metadata;
		for(my $i = 0; $i < @contents; $i++) {
			if($contents[$i] =~ /^(\w+):\s+(.*)/) {
				$metadata{$1} = $2;
				next;
			}
			if($contents[$i] =~ /^\s*$/) {
				# Found a blank line separating tagged metadata
				# from the rest of the contents. Chop off the
				# first $i lines of the file.
				splice @contents, 0, $i;
				last;
			}
			# No match. Abandon hope.
			%metadata = ();
			last;
		}

		$boxes{$boxnum} = {
			%box,
			%metadata,
			CONTENT => join('', @contents),
		}
	}
	closedir BOXES;

	%boxes;
};

#print Dumper(\%boxes);

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
