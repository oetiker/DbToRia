package DbToRia::Config;
use strict;

=head1 NAME

DbToRia::Config - The Configuration File

=head1 SYNOPSIS

 use DbToRia::Config;

 my $parser = DbToRia::Config->new(file=>'/etc/SmokeTracessas/system.cfg');
 my $cfg = $parser->parse_config();
 my $pod = $parser->make_pod();

=head1 DESCRIPTION

Configuration reader for remOcularssas.

=cut

use vars qw($VERSION);
$VERSION   = '0.01';
use Carp;
use Config::Grammar;
use base qw(Mojo::Base);

__PACKAGE__->attr('file');
    

=head1 METHODS

All methods inherited from L<Mojo::Base>. As well as the following:

=cut

=head2 $x->B<parse_config>(I<path_to_config_file>)

Read the configuration file and die if there is a problem.

=cut

sub parse_config {
    my $self = shift;
    my $cfg_file = shift;
    my $parser = $self->_make_parser();
    my $cfg = $parser->parse($self->file) or croak($parser->{err});
    return $cfg;
}

=head2 $x->B<make_config_pod>()

Create a pod documentation file based on the information fro all config actions.

=cut

sub make_pod {
    my $self = shift;
    my $parser = $self->_make_parser();
    my $E = '=';
    my $footer = <<"FOOTER";

${E}head1 COPYRIGHT

Copyright (c) 2011 by OETIKER+PARTNER AG. All rights reserved.

${E}head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

${E}head1 AUTHOR

S<Tobias Oetiker E<lt>tobi\@oetiker.chE<gt>>

${E}head1 HISTORY

 2011-02-19 to 1.0 first version

FOOTER
    my $header = $self->_make_pod_header();    
    return $header.$parser->makepod().$footer;
}



=item $x->B<_make_pod_header>()

Returns the header of the cfg pod file.

=cut

sub _make_pod_header {
    my $self = shift;
    my $E = '=';
    return <<"HEADER";
${E}head1 NAME

dbtoria.cfg - The DbToRia configuration file

${E}head1 SYNOPSIS

 *** General ***
 dsn = 
 secret = MyCookieSecret
 log_file = /tmp/dbtoria.log
 log_toppic_filter = .+

${E}head1 DESCRIPTION

Configuration overview

${E}head1 CONFIGURATION

HEADER

}

=item $x->B<_make_parser>()

Create a config parser for dbtoria.

=cut

sub _make_parser {
    my $self = shift;
    my $E = '=';
    my $grammar = {
        _sections => [ qw(General)],
        _mandatory => [qw(General)],
        General => {
            _doc => 'Global configuration settings for DbToRia',
            _vars => [ qw(dsn secret log_file log_level) ],
            _mandatory => [ qw(dsn secret log_file log_level) ],
            dsn => { _doc => 'DBI connect string', _example=>'dbi:Pg:dbname=testdb' },
            secret => { _doc => 'secret for signing mojo cookies' },
            log_file => { _doc => 'write a log file to this location'},
            log_toppic_filter => { _doc => 'rx to match against log toppics'},        
        }
    };
    my $parser =  Config::Grammar->new ($grammar);
    return $parser;
}

1;
__END__

=back

=head1 COPYRIGHT

Copyright (c) 2011 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2011-02-19 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et

