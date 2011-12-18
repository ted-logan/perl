#!/usr/bin/perl

# Format the list of nearby wireless networks into something more useful than
# the default output of iwlist. I'd envisioned importing the output from this
# script into a proper spreadsheet and running the network scan from multiple
# points in my house, but as soon as I saw the output I realized the
# channel-overlap problem and didn't need to analyze the results further.
# 
# Copyright (C) 2011 Ted Logan # http://tedlogan.com/ # ted.logan@gmail.com
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

open IWLIST, "sudo iwlist eth1 scan |"
	or die "Can't open iwlist: $!\n";

my @columns = qw(cell essid frequency channel quality signal);

print join("\t", @columns), "\n";

my %network;

while(<IWLIST>) {
	if(/Cell (\d+)/) {
		if(%network) {
			print_network(%network);
			%network = ();
		}
		$network{cell} = $1;
	}
	if(/Address: ([0-9A-F:]+)/) {
		$network{mac} = $1;
	}
	if(/Frequency:([0-9\.]+)/) {
		$network{frequency} = $1;
	}
	if(/Channel (\d+)/) {
		$network{channel} = $1;
	}
	if(/Quality=(\d+\/\d+)/) {
		$network{quality} = $1;
	}
	if(/Signal level=(-?\d+ dBm)/) {
		$network{signal} = $1;
	}
	if(/ESSID:"([^"]+)"/) {
		$network{essid} = $1;
	}
}

if(%network) {
	print_network(%network);
}

close IWLIST;

sub print_network {
	my %network = @_;

	print join("\t", map {$network{$_}} @columns), "\n";
}
