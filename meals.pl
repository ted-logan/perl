#!/usr/bin/perl

use strict;

# Minimum number of days before a specific meal can be repeated
my $meal_separation = 15;

open MEALS, "meals.list"
	or die "Can't open meal list: $!\n";
my @meals = <MEALS>;
chomp @meals;
close MEALS;

my @list;
my %valid = map {$_, undef} @meals;

my $i = 0;

while(1) {
	# If more than n meals have been prepared, return the bottom
	# element to the valid list
	if(@list > $meal_separation) {
		$valid{@list[-$meal_separation]} = undef;
	}

	# Pick a meal at random from the list
	my @valid = keys %valid;
	my $meal = $valid[rand @valid];

	printf "%2d. %s\n", ++$i, $meal;

	push @list, $meal;

	# Remove the just-used meal from the valid list
	delete $valid{$meal};

	sleep 1;
}
