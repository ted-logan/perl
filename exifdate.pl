#!/usr/bin/perl

# Sets the modification date for a group of jpegs based on the exif information

use strict;

use Image::EXIF;
use Time::Local;

my $offset = 0;
my $dryrun = 0;

foreach my $file (@ARGV) {
	if($file eq '-n') {
		$dryrun = 1;
	}

	if(my ($plus, $t) = $file =~ /^([+-])((\d+[dhms])+)$/) {
#		warn "\t$file: $plus $t\n";
		$offset = 0;
		while($t =~ /(\d+)([dhms])/g) {
			my ($num, $unit) = ($1, $2);
#			warn "\t\t$num $unit\n";
			if($unit eq 'd') {
				$offset += $num * 86400;
			} elsif($unit eq 'h') {
				$offset += $num * 3600;
			} elsif($unit eq 'm') {
				$offset += $num * 60;
			} elsif($unit eq 's') {
				$offset += $num;
			}
		}
		if($offset eq '-') {
			$offset = -$offset;
		}
		warn "Offset is $file: $offset\n";
		next;
	}

	my ($atime, $mtime) = (stat $file)[8, 9];
	unless(defined($atime)) {
		warn "$file: $!\n";
		next;
	}

	my $exif = new Image::EXIF($file);
	unless($exif) {
		warn "Error reading exif tags for $file: $!\n";
		next;
	}

	my $image_info = $exif->get_image_info();
	# 2009:03:26 11:42:42
	my @time = split /[: ]/, $image_info->{"Image Created"};
	$time[0] -= 1900;
	$time[1]--;

	my $time = timelocal(reverse @time);
	$time += $offset;

	print "$file\t", $image_info->{"Image Created"}, " -> ",
		scalar(localtime $time), "\n";

	unless($dryrun) {
		unless(utime($atime, $time, $file)) {
			warn "$file: $!\n";
		}
	}
}
