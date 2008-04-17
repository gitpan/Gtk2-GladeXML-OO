package Gtk2::GladeXML::OO;

use vars qw($VERSION $LOG $tmp);
use strict;
use warnings;
use Carp;
use base 'Gtk2::GladeXML';
#======================================================================
$VERSION = '0.371';
#======================================================================
use constant TRUE => not undef;
use constant FALSE => undef;
#======================================================================
my ($gladexml, $widget, $objects, $LOG) = (undef, undef, undef, 1);
our $AUTOLOAD;
#======================================================================
sub new {
	my $class = shift;
	$gladexml = Gtk2::GladeXML->new(@_);
	return bless $gladexml, $class;
}
#======================================================================
sub _log {
	my ($object, $method, @params) = @_;
	
	$object = '' unless defined $object;
	$method = '' unless defined $method;
	@params = () unless @params;
	for(0..$#params){
		unless(defined $params[$_]){ $params[$_] = "undef\n"; }
		else { $params[$_] .= "\n"; }
	}

	warn <<EOF
	
	
####################################
# event #
#########
	
	CALLED: $AUTOLOAD
	
	PARSING
		OBJECT: $object
		METHOD: $method
		PARAMS: @params
	
####################################
	
EOF

}
#======================================================================
# this _must_ be in check function, otherway someone could redefine our AUTOLOAD
CHECK {
#----------------------------------------------------------------------
my $autoload = *main::AUTOLOAD{CODE};
*AUTOLOAD = *main::AUTOLOAD{SCALAR};

my $imposter = sub {
	my ($object, $method, $params) = $AUTOLOAD =~ /^main::(.+)->([^\(]+)(.*)/;

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

	_log($object, $method, @params) if $LOG > 1;
		
	if(not $object){
		warn qq/\nNone object was given. Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}elsif(not $method){
		warn qq/\nNone method was given. Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}

	$objects->{$object} = $gladexml->get_widget($object) unless $objects->{$object};

	if(not $objects->{$object} and defined $main::{$object}){
		local *tmp = $main::{$object};
		$objects->{$object} = $tmp;
	}
	
	if(not $object){
		warn qq/\nUnknown object "$object"! Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}elsif(not $objects->{$object}->can($method)){
		warn qq/\nUnknown method "$method" of object "$object"! Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}
	
	$objects->{$object}->$method(@params);
	return TRUE;
};
#-------------------------------------------
# redefine main::AUTOLOAD and define debug()
{
	no warnings 'redefine';
	
	*main::AUTOLOAD = $imposter;
	
	*Gtk2::GladeXML::debug = sub { 
									my $lvl = defined $_[1] ? $_[1] : 0;
									croak(qq/Value "$lvl" is not a digit!/) if $lvl !~ /^\d+$/o;
									$LOG = $_[1]; 
									};
}
#----------------------------------------------------------------------
# End of CHECK block
}
#======================================================================
1;

=head1 NAME

Gtk2::GladeXML::OO - Drop-in replacement for Gtk2::GladeXML with object oriented interface to Glade and AUTOLOAD for all objects.


=head1 SYNOPSIS

	use Gtk2::GladeXML::OO;
	
	# exactly as in Gtk2::GladeXML
	our $gladexml = Gtk2::GladeXML::OO->new('glade/example.glade');
	$gladexml->signal_autoconnect_from_package('main');

	$gladexml->debug(2);

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

This module provides a clean and easy object-oriented interface in Glade callbacks (automagicaly loads objects and do all dirty work for you, B<no action is required on your part>). Now You can use in callbacks: widgets, Your objects or standard functions like before.

Gtk2::GladeXML::OO is a drop-in replacement for Gtk2::GladeXML, so after a change from Gtk2::GladeXML to Gtk2::GladeXML::OO all Your applications will work fine and will have new functionality.

=head1 AUTOLOAD

If You are using AUTOLOAD subroutine in main package, Gtk2::GladeXML::OO module will invoke it, when it cound'nt find any matching object in Glade file and Your code.

=head1 SUBROUTINES/METHODS

=over 4

=item B<new('/path/to/file.glade')>

This method should be called exactly as C<new> in Gtk2::GladeXML. In example:

	# Gtk2::GladeXML::OO object
	our $gladexml = Gtk2::GladeXML::OO->new('glade/example.glade');

=item B<debug>

This method turns on/off debug. Three levels are acceptable. 

	0  =>  turns OFF debug
	1  =>  turns ON debug (only important information/warnings), DEFAULT
	2  =>  turns ON debug in verbose mode, use this when You are in a trouble

In example:
	
	# tunrs OFF debug
	$gladexml->debug(0);
	
	...some code...

	# tunrs ON debug
	$gladexml->debug(1);
	
	...some code...
	# turns ON debug in verbose mode
	$gledexml->debug(2);
	


=item B<For all other methods see C<Gtk2::GladeXML>!>

=back

=head1 DEPENDENCIES

=over 4

=item Carp (in standard Perl distribution)

=item Gtk2::GladeXML

=back


=head1 INCOMPATIBILITIES

None known. You can even use AUTOLOAD in Your application and all modules.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Strzelecki £ukasz <strzelec@rswsystems.com>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

