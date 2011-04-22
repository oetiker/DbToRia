package DbToRia::DBI::Oracle;

=head1 NAME

DbToRia::DBI::Oracle - Oracle support for DbToRia

=head1 SYNOPSIS

 use DbToRia::DBI::Oracle
 ...

=head1 DESCRIPTION

All methods from L<DbToRia::DBI::base> implemented for Oracle.

This is just a stub to keep the oracle specific matching operators

=cut

use Mojo::Base 'DbToRia::DBI::base';
use DbToRia::Exception qw(error);
use Mojo::JSON;


=head2 getFilterOpsArray()

Return an array of DBMS specific comparison operators to be used in
filtering.

=cut

sub getFilterOpsArray {
    my $self = shift;
    my @ops = @{$self->SUPER::getFilterOpsArray()};
    push @ops, (
                {op   => 'BETWEEN',              type => 'dualValue',
                 help => 'value within range (not yet implemented)'},
                {op   => 'NOT BETWEEN',          type => 'dualValue',
                 help => 'value outside range (not yet implemented)'},

                {op   => 'RLIKE',                type => 'simpleValue',
                 help => 'Regexp matching; equivalent to REGEXP operator'},
                {op   => 'NOT RLIKE',            type => 'simpleValue',
                 help => 'Regexp matching; equivalent to NOT REGEXP operator'},

                # ANY, SOME, ALL
           );
    return \@ops;
}

1;

__END__

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

S<Fritz Zaucker E<lt>fritz.zaucker@oetiker.chE<gt>>,
S<David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>> (Original PostgreSQL module)

=head1 HISTORY

 2011-04-22 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:

1;

