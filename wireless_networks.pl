#!/usr/bin/perl

# Format the list of nearby wireless networks into something more useful than
# the default output of iwlist. I'd envisioned importing the output from this
# script into a proper spreadsheet and running the network scan from multiple
# points in my house, but as soon as I saw the output I realized the
# channel-overlap problem and didn't need to analyze the results further.
# 
# Copyright 2011 Ted Logan # http://tedlogan.com/ # ted.logan@gmail.com
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

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
