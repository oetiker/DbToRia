package DbToRia::Config;

use strict;

use DBI;
use Qooxdoo::JSONRPC;
use Data::Dumper;

my $singleton;

sub new {
    my $class = shift;
    $singleton ||= bless {}, $class;
}

sub getConfig 
{
    my $this = shift;
    
    # generate config if not already present
    if (!exists $this->{config}) {
	
	my $configDir = "../etc/";
	my %config;
	
	open (CONFIG, $configDir . "dbtoria.conf") or die "Failed opening file " . $configDir . "dbtoria.conf";
    
	# read config into hash, strip comments, trim keys and values
	while (<CONFIG>) {
	    
	    chomp ($_);
	    
	    # skip comments
	    if($_ =~ /^#/) {
		next;
	    }
	    
	    # limit character set and trim
	    if($_ =~ m/^([a-z_0-9]*) = (.*)$/i) {
		my $key = $1;
		my $value = $2;
		
		$key =~ s/^\s+//;
		$key =~ s/\s+$//;
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;
		
		$config{$key} = $value;
	    }
	}
	close (CONFIG);
	
	# see if we have a database specific configuration to load
	if($config{'db_type'}) {
	    
	    open (DBCONFIG, $configDir . $config{'db_type'} . ".conf") or die "Failed opening file " . $configDir . $config{'db_type'} . ".conf";
	    
	    while (<DBCONFIG>) {
		chomp ($_);
		
		# skip comments
		if($_ =~ /^#/) {
		    next;
		}
		
		# limit character set and trim
		if($_ =~ m/^([a-z_0-9]*) = (.*)$/i) {
		    my $key = $1;
		    my $value = $2;
		    
		    $key =~ s/^\s+//;
		    $key =~ s/\s+$//;
		    $value =~ s/^\s+//;
		    $value =~ s/\s+$//;
		    
		    $config{$key} = $value;
		}
	    }
	    close (DBCONFIG);
	}
	
	$this->{config} = {%config};
	return $this->{config};
    }
    else {
	return $this->{config};
    }
}

1;


##############################################################################

=head1 NAME

DbToRia::Config.pm - Simple config reader

=head1 SYNOPSIS

This module implements a very simple config reader. Basically it reads the
file dbtoria.conf in ../config/ and parses key = value pairs into a hash.
Comments start with a hash key (#).

After the initial loading of dbtoria.conf an attemept is made to load
a database specific config file. The filename is determined by the
configuration value of "db_type".

The class is implemented as a singelton so every subsequent request is handled
by the same instance. This way the configuration file only has to be loaded once.


getConfig:
   Parameters: 
   Returns: 	config hash

=head1 AUTHOR

David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>

=cut

