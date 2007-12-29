package MyObject;

our $VERSION = 0.01;
use warnings;
use strict;

sub new {
	return bless \$_[0], $_[0]; 
}

sub set_it { 
	print "I was clicked!\n"; 
}

1;
