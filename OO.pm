package Gtk2::GladeXML::OO;

our $VERSION = 0.03;
use strict;
use warnings;
#use Exporter::Lite;
require Exporter;
#======================================================================
our @ISA = qw(Exporter);
our @EXPORT = qw(_autoload_gtk);
#======================================================================
use constant TRUE => not undef;
use constant FALSE => undef;
#======================================================================
my ($widget);
my ($objects);
our $tmp;
our $LOG;
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
