#!/usr/bin/perl

# Rips a cd to oggs
# (new version)
#
# 11 December 2002
# Ted Logan
# jaeger@festing.org

use CDDB_get qw(get_cddb);

use strict;

# configuration

my $device = '/dev/dvd';
my $basedir = '/home/jaeger/media/mp3/albums';

my %config;

$config{CDDB_HOST}="freedb.freedb.org";        # set cddb host
$config{CDDB_PORT}=8880;                       # set cddb port
$config{CDDB_MODE}="cddb";                     # set cddb mode: cddb or http
$config{CD_DEVICE}=$device; 

# read the contents of the cd

print "Scanning cd...\n";

my $tempfile = "/tmp/rip-$$";

my %cddb = get_cddb(\%config);

if($cddb{title}) {
	# throw everything into a text file so the user can manipulate it
	open TEMP, ">$tempfile"
		or die "Can't open tempfile ($tempfile): $!\n";
	print TEMP "Artist: ", $cddb{artist}, "\n";
	print TEMP "Album: ", $cddb{title}, "\n";
	print TEMP "Collection: jaeger\n";
	for(my $i = 0; $i < @{$cddb{track}}; $i++) {
		print TEMP "Track ", ($i + 1), " (",
			"): ", $cddb{track}->[$i], "\n";
	}
	close TEMP;

} else {
	# the freedb has no idea about this cd
	open TEMP, ">$tempfile"
		or die "Can't open tempfile ($tempfile): $!\n";
	print TEMP "Artist: \n";
	print TEMP "Album: \n";
	print TEMP "Collection: jaeger\n";

	# spawn cdparanoia to figure out the track info
	open CDP, "cdparanoia -Q -d $device 2>&1 |"
		or die "Can't open cdparanoia: $!\n";
	while(<CDP>) {
		if(my ($track, $length) = /^\s+(\d+)\..*?\[(.*?)\]/) {
			print TEMP "Track $track ($length): \n";
		}
	}
	close CDP;
	close TEMP;
}

system("vi $tempfile") == 0
	or die "vi failed: $?\n";

# read the text file
my @tracks;
my %params;
open TEMP, $tempfile
	or die "Can't open tempfile ($tempfile): $!\n";
while(<TEMP>) {
	if(/^Track (\d+).*?: (.*)/) {
		$tracks[$1] = $2;
	} elsif(/(.*?):\s*(.*)/) {
		$params{lc $1} = $2;
	} else {
		die "Unrecogonized line: $_";
	}
}
close TEMP;
unlink $tempfile;

# figure out where to put it
my $dir = do {
	my $clean_artist = $params{artist};
	$clean_artist =~ s/\W+/_/g;

	my $clean_album = $params{album};
	$clean_album =~ s/\W+/_/g;

	"$basedir/$clean_artist/$clean_album";
};

# proceed to rip the cd
for(my $i = 1; $i < @tracks; $i++) {
	my $clean_title = $tracks[$i];
	$clean_title =~ s/\(.*?\)//g;
	$clean_title =~ s/\W+/_/g;
	$clean_title =~ s/^_+//;
	$clean_title =~ s/_+$//;

	my $oggfile = sprintf '%s/%02d-%s.ogg', $dir, $i, $clean_title;

	print '*' x 72, "\n";
	print "  Ripping track $i: $tracks[$i]\n";
	print "  $oggfile\n";
	print '*' x 72, "\n";

	system(qq'cdparanoia -d $device $i - | oggenc -Q -q 5 -a "$params{artist}" -t "$tracks[$i]" -l "$params{album}" -c "collection=$params{collection}" -c "tracknumber=$i" -o $oggfile -') == 0
		or die "cdparanoia/oggenc failed: $?\n";

	if(grep /--play/, @ARGV) {
		if($i == 1) {
			system("xmms $oggfile") == 0
				or die "xmms play failed: $?\n";
		} else {
			system("xmms --enqueue $oggfile") == 0
				or die "xmms play failed: $?\n";
		}
	}
}
