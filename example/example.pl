#!/usr/bin/perl

use warnings;
use strict;
use Gtk2 -init;
use MyObject;
use Gtk2::GladeXML;
use Gtk2::GladeXML::OO;
#======================================================================
# GLADEXML
our $gladexml = Gtk2::GladeXML->new('glade/example.glade');
$gladexml->signal_autoconnect_from_package('main');

# automatyczna obsluga wywolan standardowych
sub AUTOLOAD { _autoload_gtk($gladexml, our $AUTOLOAD, @_); }

our $myobject = MyObject->new();

#######################################################################
# function interface is avaiable too
sub gtk_main_quit { Gtk2->main_quit; }
#######################################################################

Gtk2->main;
