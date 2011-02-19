#!/usr/bin/env perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../thirdparty/lib/perl";
use Mojolicious::Commands;
use DbToRia::MojoApp;

$ENV{MOJO_APP} = ep::MojoApp->new;

# Start commands
Mojolicious::Commands->start;
