#!/usr/bin/perl

# Parse runs recorded by my Garmin Forerunner 305, and saved using
# garmin_save_runs, and output short summaries of each run.
# 
# Copyright (C) 2010 Ted Logan # http://tedlogan.com/ # ted.logan@gmail.com
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;

use XML::Parser;
use POSIX qw(floor strftime);
use Time::Local;

my $parser = new XML::Parser;
$parser->setHandlers(Start => \&parse_start);
$parser->setHandlers(End => \&parse_end);
$parser->setHandlers(Char => \&parse_char);

my @stack;
my %total;
my %lap;

foreach my $file (@ARGV) {
	my ($year, $month, $day, $hr, $min, $sec) =
		$file =~ /(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)\.gmn$/;

	my $time = timelocal($sec, $min, $hr, $day, $month - 1, $year - 1900);
	printf "%s\n", strftime("%Y-%m-%d (%A)", localtime $time);
	print "\n";
	print "Lap     Distance  Pace      Time     Avg Hrt  Max Hrt\n";
	print "        (miles)   (min/mi)  (min)    (bpm)    (bpm)  \n";
	print "------  --------  --------  -------  -------  -------\n";

	@stack = ();
	%total = ();
	my $xml = do {
		local $/ = undef;
		open XML, "garmin_dump $file |"
			or die "Can't parse $file: $!\n";
		my $inner_xml = <XML>;
		close XML;
		"<document>" . $inner_xml . "</document>";
	};
	$parser->parsestring($xml);

	print "        --------  --------  -------\n";
	printf "Total   %8.2f  %8s  %7s\n",
		$total{distance},
		print_time($total{duration} / $total{distance}),
		print_time($total{duration});
	print "\n";
	print "\n";
}

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
	my %attr = @_;

	unshift @stack, $elem;

	if($elem eq 'lap') {
		my $distance = $attr{distance} / 1609.344; # Meters to miles
		my ($hour, $minute, $second) =
			$attr{duration} =~ /(\d+):(\d\d):(\d\d\.\d\d)/;
		my $duration = $hour * 3600 + $minute * 60 + $second;
		my $pace = $duration / $distance;

		$total{distance} += $distance;
		$total{duration} += $duration;

		%lap = (
			distance => $distance,
			duration => print_time($duration),
			pace => print_time($pace),
		);
	}
}

sub parse_end {
	my ($expat, $elem) = @_;

#	if(stack_has(qw(coordinates LinearRing outerBoundaryIs Polygon Placemark))) {

	if(shift(@stack) ne $elem) {
		die "Element $elem not expected!\n";
	}

	if($elem eq 'lap') {
		printf "Lap %2d  %8.2f  %8s  %7s  %7d  %7d\n",
			++$total{laps}, $lap{distance}, $lap{pace},
			$lap{duration}, $lap{avg_hr}, $lap{max_hr};
	}
}

sub parse_char {
	my ($expat, $string) = @_;

	if(stack_has(qw(calories lap))) {
		$lap{calories} .= $string;
	} elsif(stack_has(qw(avg_hr lap))) {
		$lap{avg_hr} .= $string;
	} elsif(stack_has(qw(max_hr lap))) {
		$lap{max_hr} .= $string;
	}
}

sub print_time {
	my $sec = shift;

	my $hour = floor($sec / 3600);
	my $min = floor($sec / 60) % 60;
	$sec = $sec % 60;

	if($hour) {
		return sprintf "%d:%02d:%02d", $hour, $min, $sec;
	} else {
		return sprintf "%d:%02d", $min, $sec;
	}
}
