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
	my @columns = qw(contents current-location location label packed);

	print "<title>Box $boxnum</title></head>\n";
	print "<body>\n";
	print qq'<a href="/b/">All boxes</a>\n';
	if(exists $boxes{$boxnum}) {
		print "<h1>Box $boxnum</h1>\n";
		foreach my $label (@columns) {
			if($boxes{$boxnum}->{$label}) {
				printf "<h2>%s: %s</h2>\n",
					ucfirst($label),
					$boxes{$boxnum}->{$label};
			}
		}

		my $c = $boxes{$boxnum}->{CONTENT};
		$c =~ s/$/<br>/mg;
		$c =~ s/^\s+/&nbsp;&nbsp;&nbsp;&nbsp;/mg;
		print $c;

		print qq'<a href="/b/">All boxes</a>\n';
	} else {
		print "Box $boxnum not found!\n";
	}

} else {
	my @columns = qw(number contents packed current-location location label);

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
