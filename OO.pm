package Gtk2::GladeXML::OO;

use vars qw($VERSION $LOG $tmp);
use strict;
use warnings;
use base 'Gtk2::GladeXML';
use Hook::LexWrap qw(wrap);
#======================================================================
$VERSION = '0.361';
#======================================================================
use constant TRUE => not undef;
use constant FALSE => undef;
#======================================================================
my ($gladexml, $widget, $objects, $LOG);
#======================================================================
wrap Gtk2::GladeXML::new, post => sub { $gladexml = $_[-1]; };
#======================================================================
sub _log {
	my ($object, $method, @params) = @_;
	
	@params = () unless @params;
	print <<EOF
	
	
####################################
# event #
#########
	
	OBJECT: $object
	METHOD: $method
	PARAMS: @params
	
####################################
	
EOF

}
#======================================================================
sub Gtk2::GladeXML::debug { $LOG = $_[1]; }
#======================================================================
sub main::AUTOLOAD {
	my ($object, $method, $params) = $main::AUTOLOAD =~ /^main::(.+)->([^\(]+)(.*)/;

	my @params;
	if($params){
		$params =~ s/^\(|\)\s*$//g;
		@params = split(/(?<!\\),/, $params);

		foreach(0..$#params){
			$params[$_] =~ s/^\s+|\s+$//g;
			$params[$_] =~ s/^('|")(.*)(\1)$/$2/;
			$params[$_] =~ s/\\,/,/g;
			if($params[$_] eq 'FALSE'){ $params[$_] = FALSE; }
			elsif($params[$_] eq 'TRUE') { $params[$_] = TRUE; }
			elsif($params[$_] eq 'undef') { $params[$_] = undef; }
		}
	}else { @params = @_; } 

	_log($object, $method, @params) if $LOG;

	return unless $method;
	
	unless($objects->{$object}){$objects->{$object} = $gladexml->get_widget($object); }

	if(not $objects->{$object} and defined $main::{$object}){
		local *tmp = $main::{$object};
		$objects->{$object} = $tmp;
	}
		
	warn qq/Unknown object "$object"!\n/ and return unless $objects->{$object};
	warn qq/Unknown method "$method" of object "$object"!\n/ and return unless $objects->{$object}->can($method);
	$objects->{$object}->$method(@params);
	return TRUE;
};
#======================================================================
1;

=head1 NAME

Gtk2::GladeXML::OO - Drop-in replacement for Gtk2::GladeXML with object oriented interface to Glade and AUTOLOAD for all objects.


=head1 SYNOPSIS

	use Gtk2::GladeXML::OO;
	
	our $gladexml = Gtk2::GladeXML::OO->new('glade/example.glade');
	$gladexml->signal_autoconnect_from_package('main');

	$gladexml->debug(1);

	sub gtk_main_quit { Gtk2->main_quit; }

	# Object _MUST_ be declared as "our"
	our $myobject = MyObject->new();

	Gtk2->main;


	# ...and now callbacks in Glade can be:
	#
	#	myobject->method		<- Gtk2 will pass standard parameters to Your method
	#	myobject->method()		<- without any parameters, ie. window->hide()
	#	myobject->method("param0", "param1")	<- with Your parameters
	#
	#	gtk_main_quit			<- standard function interface, like before

	# See example.glade and example.pl in example directory!

=head1 DESCRIPTION

This module provides AUTOLOAD function for objects (automagicaly loads Your objects, B<no action is required on your part>) and object-oriented interface in Glade callbacks. Now You can use in callbacks: widgets, Your objects or standard functions like before.
Gtk2::GladeXML::OO is a drop-in replacement for Gtk2::GladeXML, so after change from Gtk2::GladeXML to Gtk2::GladeXML::OO all Your applications will work fine and will have new functionality.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new('/path/to/file.glade')>

This method should be called exactly as C<new> in Gtk2::GladeXML. In example:

	# Gtk2::GladeXML::OO object
	our $gladexml = Gtk2::GladeXML::OO->new('glade/example.glade');

=item B<debug>

This method turns on/off debug. In example:
	
	# tunrs ON debug
	$gladexml->debug(1);
	
	...some code...

	# turns OFF debug
	$gledexml->debug(0);

=item B<For all other methods see C<Gtk2::GladeXML>!>

=back

=head1 DEPENDENCIES

=over 4

=item Hook::LexWrap

=item Gtk2::GladeXML

=back


=head1 INCOMPATIBILITIES

This package will define C<AUTOLOAD> function in C<main> package. You should consider this (little work around?), when You're using AUTOLOAD in Your application (exactly main::AUTOLOAD). This will be corrected in future versions.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Strzelecki £ukasz <strzelec@rswsystems.com>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

