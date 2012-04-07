package boxes;

use strict;

use POSIX qw(strftime);

my $boxdir = '/home/jaeger/boxes';

sub boxes {
	my %boxes;

	opendir BOXES, $boxdir
		or die "Can't open $boxdir: $!\n";
	foreach my $box (grep /\.txt$/, grep {-f "$boxdir/$_"} readdir BOXES) {
		my ($boxnum) = $box =~ /(\w+)\.txt/;
		my %box = (
			number => $boxnum,
			packed => strftime("%Y-%m-%d %H:%M", localtime((stat "$boxdir/$box")[9]) ),
		);


		open BOX, "$boxdir/$box"
			or die "Can't open $box: $!\n";
		my @contents = <BOX>;
		close BOX;

		my %metadata;
		for(my $i = 0; $i < @contents; $i++) {
			if($contents[$i] =~ /^(\w+):\s+(.*)/) {
				$metadata{$1} = $2;
				next;
			}
			if($contents[$i] =~ /^\s*$/) {
				# Found a blank line separating tagged metadata
				# from the rest of the contents. Chop off the
				# first $i lines of the file.
				splice @contents, 0, $i;
				last;
			}
			# No match. Abandon hope.
			%metadata = ();
			last;
		}

		$boxes{$boxnum} = {
			%box,
			%metadata,
			CONTENT => join('', @contents),
		}
	}
	closedir BOXES;

	%boxes;
}

sub writebox {
	my $box = shift;
	my $boxnum = $box->{number};

	unless(-w "$boxdir/$boxnum.txt") {
		unlink "$boxdir/$boxnum.txt";
	}

	open BOX, ">$boxdir/$boxnum.txt"
		or die "Can't write $boxnum.txt: $!\n";

	my %metadata = %$box;
	delete $metadata{number};
	delete $metadata{packed};
	delete $metadata{CONTENT};
	foreach my $tag (keys %metadata) {
		print BOX "$tag: $metadata{$tag}\n";
	}
	if(%metadata) {
		print "\n";
	}

	print BOX $box->{CONTENT};

	close BOX;

	# Make sure the file is group-writable
	chmod 0664, "$boxdir/$boxnum.txt";
}

1;
