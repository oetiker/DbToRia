#!/usr/sepp/bin/perl-5.14.2
#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../thirdparty/lib/perl5";
use Mojolicious::Commands;
use DbToRia::MojoApp;


@ARGV = qw( daemon source ) unless @ARGV;
    
my $sourceMode = ($ARGV[1] // '') eq 'source';                
if ($sourceMode) {
    $ENV{QX_SRC_MODE} = 1;
    $ENV{QX_SRC_PATH} = "$FindBin::Bin/../../frontend";
    pop @ARGV;
}
else {
    print "Not source mode\n";
}

$ENV{MOJO_APP} = DbToRia::MojoApp->new;

# Start commands
Mojolicious::Commands->start;
