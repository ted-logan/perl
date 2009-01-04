#!/usr/bin/perl

# This proof-of-concept code outlines the algorithm I might use to decode
# geographic coordinates into human-readable descriptions. My first data source
# is the approximate outlines of wilderness areas in the United States, which
# came from (if memory serves) a GIS shape file from nationalatlas.gov and was
# converted to kml using a Windows application whose identity escapes me. This
# prototype uses Expat to parse the kml file and extract the coordinates, then
# determines the bounding box for each polygon, then determines if the polygon
# itself intersects.
#
# There's a lot I can do to clean up this existing implementation. I'd like to
# have more data sources; it might be useful to store an intermediate version
# of an in-memory representation of the data, though the full parsing takes
# a relatively modest 1.1 seconds on Portico (on battery power). Obvious
# candidates for other data sources include:
#
#   * Peaks (proximity to point)
#   * Lakes
#   * City boundaries
#   * Rivers (proximity to line)
#
# It might be instructive to identify the closest feature in each category, or
# identify the closest top several overall features. I can determine polygon
# proximity by iterating through the line segments and determining the distance
# between the segment and the point of interest.
#
# (All distance calculations should be done in square coordinates like UTM;
# pre-caching all data in UTM might make our lives easier. Care must be taken
# to avoid crossing zones indiscriminately.)

use strict;

use XML::Parser;
use Math::Geometry::Planar;

# The coordinates I care about.
#my ($point_lon, $point_lat) = (-105.68573, 39.952583); # Bob Lake, Indian Peaks

# w00t! With these coordinates, cleverly designed to fall within the bounding
# boxes outlined by the shape file, my algorithm produces exactly the right
# results for each of the three cases. (Note that the boundaries produced
# by the script are not exactly those that the wilderness outlines in the
# real world.)
#my ($point_lon, $point_lat) = (-105.6836913074988,39.92768235098271); # IPW
#my ($point_lon, $point_lat) = (-105.6719327184696,39.92910763486299); # James
my ($point_lon, $point_lat) = (-105.6647745239781,39.93100764632533); # None

# James Peak: Bounding box: lat(39.771,39.932) lon(-105.765,-105.610)
# Indian Peaks: Bounding box: lat(39.927,40.191) lon(-105.804,-105.542)

my $parser = new XML::Parser;
$parser->setHandlers(Start => \&parse_start);
$parser->setHandlers(End => \&parse_end);
$parser->setHandlers(Char => \&parse_char);
$parser->parsefile("wilderness.kml");

my @stack;
my $coordinates;
my $name;

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
#		printf "Bounding box: lat(%.3f,%.3f) lon(%.3f,%.3f)\n",
#			$min_lat, $max_lat, $min_lon, $max_lon;

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
			print "Name: $name\n";
			printf "Bounding box: lat(%.3f,%.3f) lon(%.3f,%.3f)\n",
				$min_lat, $max_lat, $min_lon, $max_lon;
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
		$name = $string;
	} elsif(stack_has(qw(coordinates LinearRing outerBoundaryIs Polygon Placemark))) {
		$coordinates .= $string;
	}
}
