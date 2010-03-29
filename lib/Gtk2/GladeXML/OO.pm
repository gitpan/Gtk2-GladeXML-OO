#line 1 "Gtk2/GladeXML/OO.pm"
package Gtk2::GladeXML::OO;

use vars qw($VERSION $LOG $tmp);
use strict;
use warnings;
use Carp;
use base 'Gtk2::GladeXML';
#======================================================================
$VERSION = '0.43';
#======================================================================
use constant TRUE => not undef;
use constant FALSE => undef;
#======================================================================
my ($gladexml, $widget, $objects, $objects_glade, $level, $LOG) = (undef, undef, undef, undef, undef, 1);
our $AUTOLOAD;
#======================================================================
sub new {
	my $class = shift;
	$gladexml = Gtk2::GladeXML->new(@_);
	return bless $gladexml, $class;
}
#======================================================================
sub debug { 
	my $lvl = defined $_[1] ? $_[1] : 0;
	croak(qq/Value "$lvl" is not a digit!/) if $lvl !~ /^\d+$/o;
	$LOG = $_[1]; 
}
#======================================================================
sub get_widget {
	my ($self, $widget) = @_;
	return undef unless defined $widget;
	$objects_glade->{$widget} = $self->SUPER::get_widget($widget) unless defined $objects_glade->{$widget};
	return $objects_glade->{$widget};
}
#======================================================================
my $log = sub {
	my ($name, $object, $method, @params) = @_;
	
	$name = '' unless defined $name;
	$object = '' unless defined $object;
	$method = '' unless defined $method;
	@params = () unless scalar @params;
	for(0..$#params){
		unless(defined $params[$_]){ $params[$_] = "undef\n"; }
		else { $params[$_] .= "\n"; }
	}

	warn <<EOF;
	
	
####################################
# event #
#########
	
	CALLED: $AUTOLOAD
	
	LEVEL:  $level
	
	PARSING
		  NAME: $name
		OBJECT: $object
		METHOD: $method
		PARAMS: @params
	
####################################
	
EOF
	$level++;
	return;
};
#======================================================================
my $parse_params = sub {
	my ($params) = @_;
	
	$params =~ s/^\(|\)\s*$//g;
	my @params = split(/(?<!\\),/, $params);

	foreach(0..$#params){
		$params[$_] =~ s/^\s+|\s+$//g;
		$params[$_] =~ s/^('|"|&quot;)(.*)(\1)$/$2/;
		$params[$_] =~ s/\\,/,/g;
		if($params[$_] eq 'FALSE'){ $params[$_] = FALSE; }
		elsif($params[$_] eq 'TRUE') { $params[$_] = TRUE; }
		elsif($params[$_] eq 'undef') { $params[$_] = undef; }
	}

	return @params;
};
#======================================================================
my $autoload = *main::AUTOLOAD{CODE};
*AUTOLOAD = *main::AUTOLOAD{SCALAR};

my $imposter = sub {
	my ($object, $method, $params) = $AUTOLOAD =~ /^main::(.+)-(?:>|&gt;)([^\(]+)(.*)/;

	# zerujemy poziom wywolania
	$level = 0;

	my (@params, $current);
	if($params){ @params = $parse_params->($params); }
	else { @params = @_; } 
		
	if(not defined $object){
		$log->($object, undef, $method, @params) if $LOG > 1;
		warn qq/\nNone object was given. Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}elsif(not defined $method){
		$log->($object, undef, $method, @params) if $LOG > 1;
		warn qq/\nNone method was given. Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}

	$objects->{$object} = $gladexml->get_widget($object) unless $objects->{$object};

	if($objects->{$object}){
		$current = $objects->{$object};
	}elsif(not $objects->{$object} and defined $main::{$object}){
		local *tmp = $main::{$object};
		$objects->{$object} = $tmp;
		$current = $tmp;
	}elsif($object =~ /^.+->.+$/o){ # zagniezdzone wywolanie => nie mozemy tego zapamietywac
		my @obj = split(/->/, $object);
		$object = shift @obj;
		
		if(defined $main::{$object}){
			local *tmp = $main::{$object};
			$current = $tmp;
		}else{ $current = $gladexml->get_widget($object); }
		
		unless($current){
			$log->($object, $current, $method, @params) if $LOG > 1;
			warn qq/\nUnknown object "$object" in multilevel call! Calling user AUTOLOAD if defined.\n\n/ if $LOG;
			defined $autoload ? return &$autoload : return;
		}

		# przechodzimy po kolejnych zagniezdzeniach
		for my $idx(0..$#obj){
			my ($method, $params) = $obj[$idx] =~ /([^\(]+)(.*)/;
			my @params = (); 
			@params = $parse_params->($params) if $params;
			$log->($object, $current, $method, @params) if $LOG > 1;
			# kasujemy nazwe obiektu, by w logach sie nie pojawiala
			# leczy tylko raz, przy pierwszej iteracji
			undef $object if $idx == 0;
			$current = $current->$method(@params);
			last unless $current;
		}
	}
	
	if(not $current){
		warn qq/\nUnknown object "$object"! Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}elsif(not $current->can($method)){
		warn qq/\nUnknown method "$method" of object "$object"! Calling user AUTOLOAD if defined.\n\n/ if $LOG;
		defined $autoload ? return &$autoload : return;
	}
	
	$log->($object, $current, $method, @params) if $LOG > 1;
	$current->$method(@params);
	return TRUE;
};

#-------------------------------------------
# redefine main::AUTOLOAD
if(exists $ENV{PAR_TEMP}){
	no warnings 'redefine';
	*main::AUTOLOAD = $imposter;
}
# this _must_ be in CHECK block too, otherway someone could redefine our AUTOLOAD
#----------------------------------------------------------------------
CHECK {
	no warnings 'redefine';
	$autoload = *main::AUTOLOAD{CODE};
	*AUTOLOAD = *main::AUTOLOAD{SCALAR};
	*main::AUTOLOAD = $imposter;
}
#----------------------------------------------------------------------
# End of CHECK block
#======================================================================
1;

#line 295
