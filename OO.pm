package Gtk2::GladeXML::OO;

use vars qw($VERSION @ISA @EXPORT $LOG $tmp);
use strict;
use warnings;
require Exporter;
#======================================================================
$VERSION = '0.034';
@ISA = qw(Exporter);
@EXPORT = qw(_autoload_gtk);
#======================================================================
use constant TRUE => not undef;
use constant FALSE => undef;
#======================================================================
my ($widget, $objects);
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
sub _autoload_gtk {
	my ($gladexml, $str) = (shift, shift);
	 
	my ($object, $method, $params) = $str =~ /^main::(.+)->([^\(]+)(.*)/;

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
}
#======================================================================
1;

=head1 NAME

Gtk2::GladeXML::OO - Object oriented interface to Glade.


=head1 SYNOPSIS

	use Gtk2::GladeXML;
	use Gtk2::GladeXML::OO;
	
	our $gladexml = Gtk2::GladeXML->new('glade/example.glade');
	$gladexml->signal_autoconnect_from_package('main');

	sub AUTOLOAD { _autoload_gtk($gladexml, our $AUTOLOAD, @_); }

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

This module provides object oriented interface in Glade callbacks. Now You can use in callbacks widget, Your objects or standard functions like before.

=head1 SUBROUTINES/METHODS

=over 4

=item B<_autoload_gtk($gladexml, our $AUTOLOAD, @_)>

This method should be called with 3 parameters somewhere in AUTOLOAD sub in main package. In example:

	sub AUTOLOAD { _autoload_gtk($gladexml, our $AUTOLOAD, @_); }

	# $galdexml - GladeXML object

=item B<$Gtk2::GladeXML::OO::LOG>

Set this variable to true for debug.

=back

=head1 DEPENDENCIES

=over 4

=item Gtk2::GladeXML

=item Exporter

=back


=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Strzelecki £ukasz <strzelec@rswsystems.com>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

