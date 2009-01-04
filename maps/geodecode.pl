#!/usr/bin/perl

use strict;

use XML::Parser;

my $parser = new XML::Parser;
$parser->setHandlers(Start => \&parse_start);
$parser->setHandlers(End => \&parse_end);
$parser->setHandlers(Char => \&parse_char);
$parser->parsefile("wilderness.kml");

my @stack;

sub stack_has {
	for(my $i = 0; $i < @_; $i++) {
		if($stack[$i] ne $_[$i]) {
			return 0;
		}
	}
	return 1;
}

sub parse_start {
	my $expat = shift;
	my $elem = shift;

	unshift @stack, $elem;

}

sub parse_end {
	my ($expat, $elem) = @_;

	if(shift(@stack) ne $elem) {
		die "Element $elem not expected!\n";
	}
}

sub parse_char {
	my ($expat, $string) = @_;

	if(stack_has(qw(name Placemark))) {
		print "Name: $string\n";
	} elsif(stack_has(qw(coordinates LinearRing outerBoundaryIs Polygon Placemark))) {
		print "Coordinates: ", substr($string, 0, 64), "\n";
	}
}
