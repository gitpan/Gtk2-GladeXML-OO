#!/usr/bin/perl

use warnings;
use strict;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::GladeXML::OO;
#======================================================================
# GLADEXML
our $gladexml = Gtk2::GladeXML->new('glade/example.glade');
$gladexml->signal_autoconnect_from_package('main');

sub AUTOLOAD { _autoload_gtk($gladexml, our $AUTOLOAD, @_); }

# see below for code of this class...
our $myobject = MyObject->new();

#######################################################################
# function interface is avaiable too
sub gtk_main_quit { Gtk2->main_quit; }
#######################################################################

Gtk2->main;

#======================================================================
#						MyObject
#======================================================================
# Here or in separate file... 
{

package MyObject;

our $VERSION = '0.01';

sub new {
	return bless \$_[0], $_[0]; 
}

sub method {
	my $self = shift;

	if($#_ == -1) {
		print "Callback without params!\n";
	} else {
		print "Parameters: @_\n"; 
	}
}

}
#======================================================================
