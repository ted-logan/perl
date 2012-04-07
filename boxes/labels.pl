#!/usr/bin/perl

# Create an OpenOffice document with labels for the boxes specified on the
# command line

use strict;

use Cwd;
use File::Basename;
use File::Temp qw(tempdir);
use boxes;

if(@ARGV != 6) {
	die "You must specify exactly six boxes\n";
}

my %boxes = boxes::boxes();

my %boxes_to_label;

foreach my $box (@ARGV) {
	if(exists $boxes{$box}) {
		$boxes_to_label{$box} = $boxes{$box};
	} else {
		die "Box $box not found\n";
	}
}

print "Preparing labels for @ARGV:\n";

my $oldpwd = cwd();
my $scriptdir = (fileparse(Cwd::realpath($0)))[1];

my $dir = tempdir(CLEANUP => 1);

print "Created temporary directory $dir\n";

chdir $dir
	or die "Can't chdir to temporary directory $dir: $!\n";

system("unzip ${scriptdir}box_template.odt") == 0
	or die "Can't unzip box template: $!\n";

# Create QR images
foreach my $box (@ARGV) {
	system("qrencode -o Pictures/$box.png -m2 http://festing.org/b/$box")==0
		or die "Can't create QR code $box: $!\n";
}

# Replace the text in the template with the actual text
foreach my $file (qw(content.xml META-INF/manifest.xml)) {
	open F, $file or die "Can't read $file: $!\n";
	$_ = do { local $/; <F>; };
	close F;

	s/BOXANUMBER/$ARGV[0]/g;
	s/BOXBNUMBER/$ARGV[1]/g;
	s/BOXCNUMBER/$ARGV[2]/g;
	s/BOXDNUMBER/$ARGV[3]/g;
	s/BOXENUMBER/$ARGV[4]/g;
	s/BOXFNUMBER/$ARGV[5]/g;

	s/BOXALOCATION/$boxes_to_label{$ARGV[0]}->{location}/g;
	s/BOXBLOCATION/$boxes_to_label{$ARGV[1]}->{location}/g;
	s/BOXCLOCATION/$boxes_to_label{$ARGV[2]}->{location}/g;
	s/BOXDLOCATION/$boxes_to_label{$ARGV[3]}->{location}/g;
	s/BOXELOCATION/$boxes_to_label{$ARGV[4]}->{location}/g;
	s/BOXFLOCATION/$boxes_to_label{$ARGV[5]}->{location}/g;

	s/BOXACONTENTS/$boxes_to_label{$ARGV[0]}->{contents}/g;
	s/BOXBCONTENTS/$boxes_to_label{$ARGV[1]}->{contents}/g;
	s/BOXCCONTENTS/$boxes_to_label{$ARGV[2]}->{contents}/g;
	s/BOXDCONTENTS/$boxes_to_label{$ARGV[3]}->{contents}/g;
	s/BOXECONTENTS/$boxes_to_label{$ARGV[4]}->{contents}/g;
	s/BOXFCONTENTS/$boxes_to_label{$ARGV[5]}->{contents}/g;

	open F, ">$file" or die "Can't write $file: $!\n";
	print F $_;
	close F;
}

# Create a new zip file
my $outfile = "boxes-" . join('-', @ARGV) . ".odt";
system("zip -r $oldpwd/$outfile .") == 0
	or die "Can't create zip file: $!\n";

print "Created $outfile\n";
