#!/usr/bin/perl

use strict;

use XML::Parser;
use Math::Geometry::Planar;

# The coordinates I care about.
#my ($point_lon, $point_lat) = (-105.68573, 39.952583); # Bob Lake, Indian Peaks
#my ($point_lon, $point_lat) = (-105.682726, 39.934355); # Rollins Pass
my ($point_lon, $point_lat) = (-105.682726, 39.934355);

# James Peak: Bounding box: lat(39.771,39.932) lon(-105.765,-105.610)
# Indian Peaks: Bounding box: lat(39.927,40.191) lon(-105.804,-105.542)

my $parser = new XML::Parser;
$parser->setHandlers(Start => \&parse_start);
$parser->setHandlers(End => \&parse_end);
$parser->setHandlers(Char => \&parse_char);
$parser->parsefile("wilderness.kml");

my @stack;
my $coordinates;

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

	if(stack_has(qw(coordinates LinearRing outerBoundaryIs Polygon Placemark))) {
		$coordinates = "";
	}
}

sub parse_end {
	my ($expat, $elem) = @_;

	if(stack_has(qw(coordinates LinearRing outerBoundaryIs Polygon Placemark))) {
		# Figure out a bounding box for the coordinates
		my ($min_lat, $max_lat);
		my ($min_lon, $max_lon);
		foreach my $coord (split /\s+/, $coordinates) {
			# Longitude is east/west
			my ($lon, $lat, $ele) = split /,/, $coord;
			if(!defined($min_lon) || $lon < $min_lon) {
				$min_lon = $lon;
			}
			if(!defined($max_lon) || $lon > $max_lon) {
				$max_lon = $lon;
			}
			if(!defined($min_lat) || $lat < $min_lat) {
				$min_lat = $lat;
			}
			if(!defined($max_lat) || $lat > $max_lat) {
				$max_lat = $lat;
			}
		}
#		print "Coordinates: ", substr($coordinates, 0, 64), "\n";
		printf "Bounding box: lat(%.3f,%.3f) lon(%.3f,%.3f)\n",
			$min_lat, $max_lat, $min_lon, $max_lon;

		# Check the bounding box against the point we care about.
		# It may be sufficient to allow the polygon's isinside() method
		# to check the intersection, but I don't want to create a bunch
		# of polygons for points that clearly don't intersect.

		# I'm also going to use the longitude and latitude as if they
		# were rectangular coordinates, which might break on a few long
		# edges, but I'm not convinced my original data is all that
		# good anyway.

		if($point_lat >= $min_lat && $point_lat <= $max_lat &&
			$point_lon >= $min_lon && $point_lon <= $max_lon) {
			print "\tBounding box intersection!\n";

			my $polygon = Math::Geometry::Planar->new();
			$polygon->points([map {[(split /,/)[0,1]]} (split /\s+/, $coordinates)]);

			if($polygon->isinside([$point_lon, $point_lat])) {
				print "\tPolygon intersection!\n";
			}
		}
	}

	if(shift(@stack) ne $elem) {
		die "Element $elem not expected!\n";
	}
}

sub parse_char {
	my ($expat, $string) = @_;

	if(stack_has(qw(name Placemark))) {
		print "Name: $string\n";
	} elsif(stack_has(qw(coordinates LinearRing outerBoundaryIs Polygon Placemark))) {
		$coordinates .= $string;
	}
}
