#!/usr/bin/perl

# Figure out when it's trash day and send a reminder

use strict;

use MIME::Lite;
use Date::Parse;
use Time::Local;
use POSIX qw(strftime);

# Western Disposal pickup holidays for 2012
# http://www.westerndisposal.com/userfiles/Tue%20E%202012.pdf
my @holidays = qw(
	2012-05-28
	2012-07-04
	2012-09-03
	2012-11-22
	2012-12-25
	2013-01-01
);

# Normally, pickups are on Tuesday.
my $pickup_wday = 2;

=for test
my $begin = str2time("2012-01-01");
my $end = str2time("2013-01-01");

for(my $date = $begin + 3600*18; $date += 86400; $date < $end) {
	my $pickup = calculate_pickup($date);
	if($pickup) {
		print strftime("%Y-%m-%d (%a)", localtime $date), " ", $pickup, "\n";
	}
}

exit;
=cut

my $pickup = calculate_pickup();
exit unless $pickup;
my $wday = strftime "%A", localtime;

my $msg = MIME::Lite->new(
	From	=> 'Friendly Automated Reminder <jaeger@festing.org>',
	To	=> 'Ted Logan <jaeger@festing.org>, ' .
		'Gem Stone-Logan <kiesa@festing.org>',
	Subject	=> "$pickup Reminder",
	Data	=> "Today is $wday, which is a $pickup day. Have a nice week."
);

$msg->send();

# Trash pickup is every Tuesday, unless a holiday fell earlier in the week
sub calculate_pickup {
	my $now = @_ ? shift : time;
	my @now = localtime($now);
	my $midnight = timegm(0, 0, 0, $now[3], $now[4], $now[5]);
	my $sunday = $midnight - $now[6] * 86400;

	my $holiday;
	foreach my $h (map {str2time($_)} @holidays) {
		if($h >= $sunday && $h < $sunday + 3600*24*7) {
			$holiday = $h;
			last;
		}
	}

	if(defined $holiday) {
		if($now[6] == $pickup_wday) {
			if($holiday <= $midnight) {
				return undef;
			}
		} elsif($now[6] == $pickup_wday + 1) {
			if($holiday >= $midnight) {
				return undef;
			}
		} else {
			return undef;
		}
	} else {
		if($now[6] != $pickup_wday) {
			# Normal, non-holiday week.
			return undef;
		}
	}

	# Recycling pickup is every other week, starting with the week
	# of 27 December 2011
	my $first_recycling_pickup = str2time("2011-12-27", "GMT");
	my $week = int(($sunday - $first_recycling_pickup) / (3600*24*7));

	if($week % 2 == 0) {
		return "Trash and Compost";
	} else {
		return "Trash and Recycling";
	}
}
