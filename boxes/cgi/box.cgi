#!/usr/bin/perl

use strict;

BEGIN {
	my $scriptdir;

	$scriptdir = $ENV{SCRIPT_FILENAME};
	$scriptdir =~ s#/[^/]+/[^/]+$##;
	push @INC, $scriptdir;
}

use boxes;

print "content-type: text/html\n\n";

my %boxes = boxes::boxes();

my ($boxnum) = $ENV{REQUEST_URI} =~ m#/(\d+)#;

print <<HTML;
<html>
<head>
<meta name="viewport" content="width=device-width, user-scalable=no" />
HTML

if($boxnum) {
	print "<title>Box $boxnum</title></head>\n";
	print "<body>\n";
	print qq'<a href="/b/">All boxes</a>\n';
	if(exists $boxes{$boxnum}) {
		print "<h1>Box $boxnum</h1>\n";
		print "<h2>Contents: $boxes{$boxnum}->{contents}</h2>\n";
		print "<h2>Location: $boxes{$boxnum}->{location}</h2>\n";
		print "<h2>Label: $boxes{$boxnum}->{label}</h2>\n";

		my $c = $boxes{$boxnum}->{CONTENT};
		$c =~ s/$/<br>/mg;
		print $c;

		print qq'<a href="/b/">All boxes</a>\n';
	} else {
		print "Box $boxnum not found!\n";
	}

} else {
	my @columns = qw(number contents location label);

	print "<title>Boxes</title></head>\n";
	print "<table>\n";
	print "<tr>", map { "<th>" . lcfirst($_) . "</th> " } @columns;
	print "</tr>\n";

	foreach my $box (sort {$a <=> $b} keys %boxes) {
		print "<tr>",
			map { "<td><a href=\"/b/$box\">" . $boxes{$box}->{$_} . "</a></td>" } @columns;
		print "</tr>\n";
	}
	print "</table>\n";
}

print "</body></html>\n";
