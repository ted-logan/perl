#!/usr/bin/perl

use strict;

use XML::DOM;
use POSIX qw(strftime);

my $parser = new XML::DOM::Parser;

print "Parsing file...\n";
my $gnucash = $parser->parsefile("/home/kiesa/finances/Finances");
unless($gnucash) {
	die "Gnucash parsing failed\n";
}

print "Loading accounts...\n";

my %accounts;
my %fullnames;

foreach my $account ($gnucash->getElementsByTagName('gnc:account')) {
#	print $i++, ": $account\n";

	my %account;

	if(my @d = $account->getElementsByTagName('act:name')) {
		$account{name} = $d[0]->getFirstChild()->getData();
	}
	if(my @d = $account->getElementsByTagName('act:id')) {
		$account{id} = $d[0]->getFirstChild()->getData();
	}
	if(my @d = $account->getElementsByTagName('act:parent')) {
		$account{parent} = $d[0]->getFirstChild()->getData();
	}

	# determine the account's full name
	if($account{parent}) {
		$account{fullname} = $accounts{$account{parent}}->{fullname} . ':' . $account{name};
	} else {
		$account{fullname} = $account{name};
	}

#	print "    Name = $account{name}\n";
#	print "    Full Name = $account{fullname}\n";
#	print "    Id = $account{id}\n";

	$accounts{$account{id}} = \%account;
	$fullnames{$account{fullname}} = $account{id};

#	last if $i >= 5;
}

# 
# Get each transaction
#

#my $i = 0;

print "Adding transactions...\n";

foreach my $tx ($gnucash->getElementsByTagName('gnc:transaction')) {
#	my $desc = ($tx->getElementsByTagName('trn:description'))[0]->getFirstChild()->getData();

#	print "Transaction: $desc\n";

	my $splits = ($tx->getElementsByTagName('trn:splits'))[0];
	foreach my $split ($splits->getElementsByTagName('trn:split')) {
		my $account = ($split->getElementsByTagName('split:account'))[0]->getFirstChild()->getData();
		my $value = ($split->getElementsByTagName('split:value'))[0]->getFirstChild()->getData();
		$value =~ s#/.*##;

#		printf "    \$%8.2f  %s\n",
#			$value, $accounts{$account}->{fullname};

		$accounts{$account}->{balance} += $value;
	}

#	print "\n";

#	last if ++$i > 10;
}

print "Freeing memory...\n";
$gnucash->dispose();

#
# Report the current status of the budget items we care about
#

my @firstbank = grep /^Assets:Checking:1st Bank Checking:/, keys %fullnames;

print "Opening gnumeric report...\n";

my $report = $parser->parsefile("zcat /home/jaeger/official_budget.gnumeric |");
unless($report) {
	die "Budget report parsing failed\n";
}

print "Generating report...\n";

my $state = 0;
my $value = undef;

foreach my $cell ($report->getElementsByTagName('gmr:Cell')) {
	my $child = $cell->getFirstChild();
	next unless $child;

	my $col = $cell->getAttribute('Col');
	my $row = $cell->getAttribute('Row');

	if($col == 0 && $row == 0) {
		$child->setData(strftime("%d %B %Y", localtime));
	}

	if($col == 0 && $row == 3) {
		$state = 1;
	}

	if($col == 0 && $state == 1) {
		if($child->getData() eq 'Totals') {
			$state = 2;
		} else {
			my $item = $child->getData();

			# Locate the budget in question under
			# Assets:Checking:1st Bank Checking
			my ($fn) = grep /:$item/, @firstbank;

			if($fn) {
				my $acct = $accounts{$fullnames{$fn}};
				$value = $acct->{balance} / 100;
			} else {
				warn "Unable to locate budget item $item\n";
				$value = undef;
			}
		}
	}

	if($col == 5 && $state == 1) {
		# 40 is a floating-point number
		$cell->setAttribute('ValueType', '40');
		$child->setData($value);
	}
}

print "Writing gnumeric report...\n";

open REPORT, "| gzip > /home/jaeger/official_budget.gnumeric"
	or die "Can't span gzip: $!\n";
$report->printToFileHandle(\*REPORT);
close REPORT;
