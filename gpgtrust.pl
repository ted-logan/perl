#!/usr/bin/perl

# $Id: gpgtrust.pl,v 1.1 2004-01-14 02:29:50 jaeger Exp $

# Computes my GnuPG trust web

use strict;

open GPG, "gpg --with-colons --list-sigs |"
	or die "Can't open gpg: $!\n";

my %keys;

my $thiskey;

while(<GPG>) {
	chomp;
	my @fields = split /:/;

	if($fields[0] eq 'pub') {
		$thiskey = $fields[4];
		$keys{$thiskey}->{info} = \@fields;
	} elsif($fields[0] eq 'sig') {
		next if $thiskey eq $fields[4];

		$keys{$thiskey}->{trusted_by}->{$fields[4]}++;
		$keys{$fields[4]}->{trusts}->{$thiskey}++;
	}
}

close GPG;

#
# Mark the keys we care about
#

# Start with my key
$keys{C458DB9E46DFA452}->{care} = 1;

my $newcare;

do {
	$newcare = 0;

	foreach my $key (values %keys) {
		next unless $key->{care};

		my @trusts = $key->{trusts} ? keys %{$key->{trusts}} : ();
		my @trusted_by = $key->{trusted_by} ? keys %{$key->{trusted_by}} : ();

		foreach my $trust (@trusts, @trusted_by) {
			unless($keys{$trust}->{care}++) {
				$newcare++;
			}
		}
	}
} while($newcare);

#
# Display all of the keys
#

foreach my $key (values %keys) {
	next unless $key->{info};
	next unless $key->{care};

	my $keyid = lc substr $key->{info}->[4], -8;
	print "0x$keyid $key->{info}->[5] ";
	if($key->{info}->[6]) {
		print "[$key->{info}->[6]] ";
	}
	print "$key->{info}->[1] $key->{info}->[9]\n";

	my %trusts = $key->{trusts} ? %{$key->{trusts}} : ();
	my %trusted_by = $key->{trusted_by} ? %{$key->{trusted_by}} : ();
	my %bitrust;

	foreach my $key (keys %trusts) {
		if(exists $trusted_by{$key}) {
			$bitrust{$key} = 1;
			delete $trusts{$key};
			delete $trusted_by{$key};
		}
	}

	if(%bitrust) {
		print "    Bitrust:\n";
		foreach my $trust_id (keys %bitrust) {
			my $trust = $keys{$trust_id}->{info};
			my $tid = substr $trust_id, -8;

			print "        $tid $trust->[9]\n";
		}
	}

	if(%trusts) {
		print "    Trusts:\n";
		foreach my $trust_id (keys %trusts) {
			my $trust = $keys{$trust_id}->{info};
			my $tid = substr $trust_id, -8;

			print "        $tid $trust->[9]\n";
		}
	}
	if(%trusted_by) {
		print "    Trusted by:\n";
		foreach my $trust_id (keys %trusted_by) {
			my $trust = $keys{$trust_id}->{info};
			my $tid = substr $trust_id, -8;
			if($trust) {
				print "        $tid $trust->[9]\n";
			} else {
				print "        $tid (not found)\n";
			}
		}
	}
	print "\n";
}
