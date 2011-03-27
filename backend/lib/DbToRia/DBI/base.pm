package DbToRia::DBI::base;


=head1 NAME

DbToRia::DBI::base - base class for database drivers

=head1 SYNOPSIS

 use base qw(DbToRia::DBI::base);
 ...

=head1 DESCRIPTION

DbToRia uses DBI for database introspection wherever possible. For the non
generic bits it uses the services of a database driver module. This is the base class for
implementing such driver modules.

A driver module must implement the following methods:

=cut

use strict;
use warnings;
use Mojo::Base -base;

=head2 map_type(type_name)

Map a native database column type to a DbToRia field type:

 varchar
 integer
 float
 boolean
 datatime

=cut

sub map_type {
    my $self = shift;
    return "varchar";
}

=head2 db_to_fe(value,type)

Convert the data returned from an sql query to something suitable for the frontend according to the database type.

=cut

sub db_to_fe {
    my $self = shift;
    my $value = shift;
    my $type = shift;
    return $value
}

1;


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

 2011-02-20 to 1.0 first version

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

