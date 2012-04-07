#!/usr/bin/perl

use strict;

use boxes;

my %tags;

while($ARGV[0] =~ /^(\w+):\s*(.*)/) {
	$tags{$1} = $2;
	shift;
}

my %boxes = boxes::boxes();

foreach my $box (@ARGV) {
	if(exists $boxes{$box}) {
		print "Box $box:\n";
		foreach my $tag (keys %tags) {
			print "\tSetting $tag: $tags{$tag}";
			if($boxes{$box}->{$tag}) {
				print " (was ", $boxes{$box}->{$tag}, ")";
			}
			print "\n";

			$boxes{$box}->{$tag} = $tags{$tag};
		}

		boxes::writebox($boxes{$box});
	}
}
