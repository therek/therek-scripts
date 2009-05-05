package WxTestApp;
use strict;

use Wx;

use base 'Wx::App';

sub OnInit {
	Wx::Event::EVT_LEFT_UP(
		$_[0],
		sub {
			print "You clicked left mouse button!\n";
			$_[1]->Skip(1);
		}
	);
	Wx::Event::EVT_LEFT_DCLICK(
		$_[0],
		sub {
			print "You double-clicked left mouse button!\n";
			$_[1]->Skip(1);
		}
	);
	Wx::Event::EVT_MIDDLE_UP(
		$_[0],
		sub {
			print "You clicked middle mouse button!\n";
			$_[1]->Skip(1);
		}
	);
	Wx::Event::EVT_RIGHT_UP(
		$_[0],
		sub {
			print "You clicked right mouse button!\n";
			$_[1]->Skip(1);
		}
	);

	my $frame = Wx::Frame->new(undef,-1,"test");
	$frame->Show;
}

1;
