#!/usr/bin/env perl
#!/usr/sepp/bin/perl-5.12.3-to
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../thirdparty/lib/perl5";
use Mojolicious::Commands;
use DbToRia::MojoApp;

$ENV{MOJO_APP} = DbToRia::MojoApp->new;

# Start commands
Mojolicious::Commands->start;
