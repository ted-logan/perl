#!/usr/bin/perl

# $Id: colorlog.pl,v 1.1 2005-01-31 01:52:31 jaeger Exp $

# Parses an Apache combined log file and spits it out using pretty ANSI
# colors for ease of reading.

use strict;

{
	my %numtoname;

	sub numtoname {
		local($_) = @_;
		unless(defined $numtoname{$_}) {
			my (@a) = gethostbyaddr(pack('C4', split(/\./)), 2);
			$numtoname{$_} = @a > 0 ? $a[0] : $_;
		}
		return $numtoname{$_};
	}
}

{
	my %colors = (
		black => 30,
		red => 31,
		green => 32,
		yellow => 33,
		blue => 34,
		magenta => 35,
		cyan => 36,
		white => 37
	);

	sub color {
		my $text = shift;
		my $cname = shift;
		my $bright = ($cname =~ s/^br//) ? '1:' : '';
		my $color = $colors{$cname};
		return "\e[$bright${color}m$text\e[0m";
	}
}

while(<>) {
	my ($ip, $date, $request, $return, $length, $refer, $ua) =
		/^([0-9.]+) - - \[(.*?)\] "(.*?)" (.+) (.+) "(.*?)" "(.*?)"/;

	# apply fun colors
	$ip = color(numtoname($ip), 'brwhite');
	$date = color($date, 'yellow');
	$request = color($request, 'cyan');
	if($return =~ /^4/) {
		$return = color($return, 'brred');
	}
	$refer = color($refer, 'green');
	$ua = color($ua, 'magenta');

	print qq'$ip - - [$date] "$request" $return $length "$refer" "$ua"\n';
}
