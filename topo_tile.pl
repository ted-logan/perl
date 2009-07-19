#!/usr/bin/perl

# My ultimate goal for this script is to convert a PDF containing a USGS
# topographic map into a number of tiles for use in Google Earth or my own
# not-yet-written mapping application. My algorithm so far is:
#
# 1. Rasterize the PDF. (My first test is at 100 dpi, which is adequate for
#    test purposes but not for final production.)
# 2. Figure out where the corners of the map are. This may be best done
#    manually.
# 3. Deskew the image. In my test, it seemed to be as easy as rotating the
#    image by the correct angle, calculated as the average of the angles
#    between the corners.
# 4. Crop the image into one or more tiles. For 7.5-minute quads, I'm thinking
#    2.5" tiles.
# 5. Convert the corner coordinates from NAD-27 to WGS-84, and possibly into
#    UTM.

use strict;

use File::Temp qw(tempfile tempdir);
use Geo::Coordinates::DecimalDegrees;
use Image::Magick;
use Math::NumberCruncher;
use Math::Trig;
use Math::Trig ':pi';

sub read_pixel_coords {
	while(1) {
		my $coords = <>;
		if(my @c = $coords =~ /^\s*(\d+)\s*[, ]\s*(\d+)/) {
			return @c;
		}
	}
}

sub read_dms {
	my @c;
	do {
		my $c = <>;
		chomp $c;
		@c = split /\s+/, $c;
	} while(@c < 1);
	while(@c < 3) {
		push @c, 0;
	}
	return dms2decimal(@c);
}

print "Enter state: ";
my $state = <>; chomp $state;

print "Enter quad name: ";
my $name = <>; chomp $name;

print "Enter image filename: ";
my $filename = <>; chomp $filename;

# Determine the image size so we know where the center is
my ($width, $height) = do {
	my $img = new Image::Magick;
	if($img->Read($filename)) {
		die "Unable to read image $filename\n";
	}
	$img->Get('width', 'height');
};

print "Enter pixel coordinates of top-left corner: ";
my @top_left = read_pixel_coords();

print "Enter pixel coordinates of top-right corner: ";
my @top_right = read_pixel_coords();

print "Enter pixel coordinates of bottom-left corner: ";
my @bottom_left = read_pixel_coords();

print "Enter pixel coordinates of bottom-right corner: ";
my @bottom_right = read_pixel_coords();

# Input coordinates in NAD-27
print "Enter latitude of the northern edge of the map: ";
my $north = read_dms();

print "Enter latitude of the southern edge of the map: ";
my $south = read_dms();

print "Enter longitude of the eastern edge of the map: ";
my $east = read_dms();

print "Enter longitude of the western edge of the map: ";
my $west = read_dms();

#
# Calculate the angle to rotate the map by
#
my $rotate = - do {
	sub angle {
		return atan2($_[1]->[1] - $_[0]->[1], $_[1]->[0] - $_[0]->[0]);
	}

	my @a;

	# top edge
	push @a, angle(\@top_left, \@top_right);
	# bottom edge
	push @a, angle(\@bottom_left, \@bottom_right);
	# left edge
	push @a, angle(\@top_left, \@bottom_left) - pip2; # PI/2
	# right edge
	push @a, angle(\@top_right, \@bottom_right) - pip2; # PI/2

	Math::NumberCruncher::Mean(\@a);
};

print "\n\n";
printf "Image should be rotated by %.5f degrees\n", rad2deg($rotate);

# convert -density 200x200 /home/jaeger/gps/maps/topo/OR_Jubilee_Lake_O45117G8_geo.PDF -depth 8 OR_Jubilee_Lake_200dpi.png

# Rotate the points around the top-right corner of the image so we know where
# to crop
sub rotate {
	my ($x, $y, $angle) = @_;
	$x -= $width;
	my $x_new = $width + cos($angle)*$x - sin($angle)*$y;
	my $y_new = sin($angle)*$x + cos($angle)*$y;
	return ($x_new, $y_new);
}

@top_left = rotate(@top_left, $rotate);
@top_right = rotate(@top_right, $rotate);
@bottom_left = rotate(@bottom_left, $rotate);
@bottom_right = rotate(@bottom_right, $rotate);

=for later
# Check how close each edge is
my $delta_left = abs($top_left[0] - $bottom_left[0]);
my $delta_right = abs($top_right[0] - $bottom_right[0]);
my $delta_top = abs($top_left[1] - $top_right[1]);
my $delta_bottom = abs($bottom_left[1] - $bottom_right[1]);

printf "Delta left: %d\n", $delta_left;
printf "Delta right: %d\n", $delta_right;
printf "Delta top: %d\n", $delta_top;
printf "Delta bottom: %d\n", $delta_bottom;

# TODO: Come up with some metrics to determine what acceptable deltas are.
# If they're too far off, odds are either the image is skewed (not simply
# rotated) or the coordinates were entered wrong.
=cut

my $left = Math::NumberCruncher::Mean([$top_left[0], $bottom_left[0]]);
my $right = Math::NumberCruncher::Mean([$top_right[0], $bottom_right[0]]);
my $top = Math::NumberCruncher::Mean([$top_left[1], $top_right[1]]);
my $bottom = Math::NumberCruncher::Mean([$bottom_left[1], $bottom_right[1]]);

my $crop = sprintf "%dx%d+%d+%d", $right - $left, $bottom - $top, $left, $top;

print "Crop geometry: $crop\n";

my $kmzdir = tempdir(CLEANUP => 1);

# Rotate and crop the file into the temp directory we've created for the kmz
my $jpeg = $filename;
$jpeg =~ s/.*\///;
$jpeg =~ s/\.[a-z]+$/.jpg/i;

print "Rotating and cropping $filename (to $kmzdir/$jpeg)...\n";
system("convert -depth 8 \"$filename\" -rotate $rotate -crop $crop \"$kmzdir/$jpeg\"") == 0
	or die "Unable to rotate and crop image\n";
print "done.\n";

#
# Convert coordinates to WGS-84
#

# Create a "universal CSV" file for gpsbabel
# Note that this requires gpsbabel >= 1.3.4
my ($infh, $unicsv) = tempfile();
print $infh "name,lon,lat\n";
printf $infh "north,%.6f,%.6f\n", ($east + $west) / 2, $north;
printf $infh "south,%.6f,%.6f\n", ($east + $west) / 2, $south;
printf $infh "east,%.6f,%.6f\n", $east, ($north + $south) / 2;
printf $infh "west,%.6f,%.6f\n", $west, ($north + $south) / 2;
close $infh;

my ($outfh, $csv) = tempfile();

system("gpsbabel -i unicsv,datum='N. America 1927 mean' -f $unicsv -o csv -F $csv") == 0
	or die "Failed to run gpsbabel to convert datums\n";

unlink $unicsv;

my %point;
while(<$outfh>) {
	chomp;
	my ($lat, $lon, $name) = split /,\s*/;
	$point{$name} = [$lon, $lat];
}

close $outfh;
unlink $csv;

# Write the KML file with the coordinates
open KML, ">$kmzdir/doc.kml"
	or die "Can't open doc.kml: $!\n";
print KML <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<GroundOverlay>
        <name>$state - $name</name>
        <Icon>
                <href>$jpeg</href>
        </Icon>
        <LatLonBox>
                <north>$point{north}->[1]</north>
                <south>$point{south}->[1]</south>
                <east>$point{east}->[0]</east>
                <west>$point{west}->[0]</west>
        </LatLonBox>
</GroundOverlay>
</kml>
XML
close KML;

# Create the kmz
my $kmz = $filename;
$kmz =~ s/\.[a-z]+$/.kmz/i;
print "Generating $kmz ...\n";
system("zip -j $kmz $kmzdir/*") == 0
	or die "Unable to create kmz\n";
print "Done.\n";
