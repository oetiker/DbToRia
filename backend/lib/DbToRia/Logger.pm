package DbToRia::Logger;

use strict;

sub write
{
    shift;
    my $content = shift;
    my $call = shift;
    open (LOG, ">> ../../logfile");
    print LOG $call . ": " .$content . "\n";
    close (LOG);
}

1;
