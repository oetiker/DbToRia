package DbToRia::Meta::base;


=head1 NAME

DbToRia::Meta::base - base class for database meta information reader

=head1 SYNOPSIS

 use Mojo::Base 'DbToRia::Meta::base';
 ...

=head1 DESCRIPTION

DbToRia builds user friendly databse frontends automatically. It does this
by pulling meta information on the data in store directly from the database.
Often this is not enough, to build a realy user friendly frontend.

The Meta modules remedy this by enhancing the original meta data with
additional information.

This is the base class for writing meta modules.

=cut

use strict;
use warnings;
use Encode;
use DbToRia::Exception qw(error);
use Mojo::Base -base;

has 'DBI';
has 'cfg';

=head2 prepare()

If information has to be pulled from the database prior to using the engine,
do it in this function as it will be called after the database has been
connected.

=cut

sub prepare {
    my $self = shift;
}

=head2 massageTables(tablelist)

Updates the table list created by L<DbToRia::DBI::base::getTables>.

=cut

sub massageTables {
    my $self = shift;
    my $tables = shift;
}

=head2 massageTableStructure(tableId,tableStructure)

Updates the tableStructure initially created by L<DbToRia::DBI::base::getTableStructure>.

=cut

sub massageTableStructure {
    my $self = shift;
    my $tableId = shift;
    my $structure = shift;
} 

=head2 massageListView(tableId,listView) 

Updates the information on how to display the table content in a tabular format

=cut

sub massageListView {
    my $self = shift;
    my $tableId = shift;
    my $listView = shift;
}

=head2 massageEditView(tableId,editView)

Updates the information on how to display a single record for editing.

=cut

sub massageEditView {
    my $self = shift;
    my $tableId = shift;
    my $editView = shift;
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

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>,

=head1 HISTORY

 2011-03-30 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:

=head2 massageEditView(tableId,editView)

Updates the information on how to display a single record for editing.

=cut

sub massageRecord {
}

1;

