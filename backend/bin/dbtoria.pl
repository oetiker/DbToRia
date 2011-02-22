#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../thirdparty/lib/perl5";
use Mojolicious::Commands;
use DbToRia::MojoApp;

if ($ARGV[0] || '' eq  'daemon-source'){
    $ENV{RUN_QX_SOURCE} = 1;
    $ARGV[0] = 'daemon';

}

$ENV{MOJO_APP} = DbToRia::MojoApp->new;

# Start commands
Mojolicious::Commands->start;
