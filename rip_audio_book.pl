#!/usr/bin/perl

use strict;

my $title = "Welcome to the Monkey House";
my $author = "Kurt Vonnegut";
my $first_disk = 1;

my $lastpid = undef;

for(my $i = $first_disk; ; $i++) {
	print '=' x 72, "\n";
	print " Please insert disk ", $i, " and press enter, or ctl+c when done\n";
	print '=' x 72, "\n";
	scalar <STDIN>;

	my $disk = sprintf "%02d", $i;

	system("cdparanoia '1-' $disk.wav") == 0
		or die "\ncdparanoia failed\n";
	system("eject");

	if(defined $lastpid) {
		print "Waiting for encoder to finish...\n";
		waitpid($lastpid, 0);
	}

	# Fork a process to do the encoding
	$lastpid = fork();
	unless(defined $lastpid) {
		die "Fork failed: $!\n";
	}
	if($lastpid == 0) {
		# Child
		system("faac $disk.wav -o \"$title - Disk $disk.m4a\" " .
			"--artist \"$author\" " .
			"--album \"$title\" " .
			"--title \"$title (Disk $disk)\" " .
			"--track $disk >/dev/null") == 0
			or die "faac failed\n";
		rename "$title - Disk $disk.m4a", "$title - Disk $disk.m4b";
		unlink "$disk.wav";
		exit;
	}
	# Parent; keep on looping
}
