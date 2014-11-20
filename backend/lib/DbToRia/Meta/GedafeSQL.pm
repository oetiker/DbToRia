package DbToRia::Meta::GedafeSQL;

=head1 NAME

DbToRia::Meta::Gedafe - read naming information gedafe style out of
the database structure

=head1 SYNOPSIS

 use DbToRia::Meta::GedafeSQL

=head1 DESCRIPTION

DbToRia can be used as a drop-in replacement for gedafe. The
compatibility layer for Gedafe SQL nameing conventions is reaslized by
this module. See L<http://isg.ee.ethz.ch/tools/gedafe/> for details on
Gedafe.

=cut

use strict;
use warnings;
use Encode;
use DbToRia::Exception qw(error);
use Mojo::Base 'DbToRia::Meta::base';
use Time::HiRes qw(time);


=head2 prepare()

This function is called right after the database has been connected.
It gets all tables and their structure and replaces column names with
their comments if they exist.

=cut

sub prepare {
    my $self = shift;
    my $tables = $self->DBI->getAllTables();
    my %colHash;
    for my $table (keys %$tables) {
        next unless $tables->{$table}{type} eq 'TABLE';
        my $structure = $self->DBI->getTableStructureRaw($table);
        my $columns   = $structure->{columns};
        for my $col (@$columns) {
            $colHash{$col->{id}} = $col->{remark} if $col->{remark};
        }
    }
    $self->{colHash} = \%colHash;
}

=head2 massageDatabaseName(tablelist)

Update the database name created by L<DbToRia::DBI::Pg::getDatabaseName>.
Replace table name with database comment if it exists.

=cut

sub massageDatabaseName {
    my $self           = shift;
    my $databaseName   = shift;
    my $databaseRemark = shift;
    $databaseName = $databaseRemark if ($databaseRemark);
    return $databaseName;
}


=head2 massageTables(tablelist)

Updates the table list created by L<DbToRia::DBI::base::getTables>.
Replace table name with table comment if it exists. Applies optional
regex supplied in DbToRia config on table name.

=cut

sub massageTables {
    my $self = shift;
    my $tables = shift;
    my $tablenamesReplacer = exists $self->{cfg}{tablenamesReplace} ? eval 'sub { $_[0] =~ '.$self->{cfg}{tablenamesReplace}.'}' : sub {};
    for my $table (keys %$tables) {
        if ($tables->{$table}{type} eq 'VIEW' and $table =~ /_(list|combo)$/ ){
            delete $tables->{$table};
            next;
        }
        $tables->{$table}{name} = $tables->{$table}{remark} if exists $tables->{$table}{remark};
        $tablenamesReplacer->( $tables->{$table}{name} );
    }
}

=head2 massageToolbarTables(tablelist)

Updates the table toolbar list created by
L<DbToRia::DBI::base::getToolbarTables>. It uses an optional regex
from the DbToRia config file to filter the table list.

=cut

sub massageToolbarTables {
    my $self = shift;
    my $tables = shift;
    my $toolbarTables = exists $self->{cfg}{toolbarTables} ? eval 'sub { $_[0] =~ '.$self->{cfg}{toolbarTables}.' }' : sub { 1 };
    my @tbTables;
    for my $table (@$tables) {
        $table->{name} = $table->{remark} if defined $table->{remark};
        next unless $toolbarTables->( $table->{name} );
        push @tbTables, $table;
    }
    @$tables = sort { $a->{name} cmp $b->{name} }  @tbTables;
}


=head2 massageTableStructure(tableId,tableStructure)

Updates the tableStructure initially created by
L<DbToRia::DBI::base::getTableStructure>.

=cut

sub massageTableStructure {
    my $self      = shift;
    my $tableId   = shift;
    my $structure = shift;
    if ($tableId =~ /_(combo|list)$/){
        $structure->{columns}[0]{primary} = 1;
        $structure->{meta}{primary} = [ $structure->{columns}[0]{id} ];
        if ($tableId =~ /_list$/ and $structure->{columns}[1]{id} =~ /_hid$/){
            $structure->{columns}[0]{hidden}  = 1;
        }
    }
    my $colHash   = $self->{colHash};
    for my $col (@{$structure->{columns}}) {
        my $id = $col->{id};
        $col->{hidden} = 1 if $id eq 'meta_sort';
        if ( $col->{remark} ) {
            $col->{name} = $col->{remark};
        }
        elsif ( $colHash->{$id} ) {
            $col->{name} = $colHash->{$id};
        }
    }
}

=head2 massageListView(tableId,listView)

Updates the information on how to display the table content in a
tabular format.

=cut

sub massageListView {
    my $self = shift;
    my $view = shift;
    my $vColumns = $view->{columns};
    my $tables = $self->DBI->getAllTables();
    if ($tables->{$view->{tableId}.'_list'}){
        my $newView = $self->DBI->prepListView($view->{tableId}.'_list');
        map { $view->{$_} = $newView->{$_} } keys %$newView;
    }
    for my $col (@{$view->{columns}}) {
        for my $vCol (@$vColumns) {
            if ($col->{id} eq $vCol->{id}) {
                $col->{fk} = $vCol->{fk};
            }
        }
    }
}

=head2 massageEditView(tableId,editView)

Updates the information on how to display a single record for editing.

=cut

sub massageEditView {
    my $self = shift;
    my $tableId = shift;
    my $editView = shift;
    my $tables = $self->DBI->getAllTables();
    for my $row (@$editView){
        next unless $row->{type} eq 'ComboTable';
	die error(90732,"ComboTable view $row->{tableId}_combo not found.") unless exists $tables->{$row->{tableId}.'_combo'};
	$row->{tableId} .= '_combo';
	$row->{idCol} = 'id';
	$row->{valueCol} = 'text';
    }
    for (my $i=0; $i<scalar @$editView; $i++) {
        my $row = $editView->[$i];
        if ($row->{name} =~ m/_id$/) {
            splice @$editView, $i, 1;
            last;
        }
    }
}


=head2 massageRecord(tableId, recordId, record)

Updates the information that is returned to the backend for a single
record.

=cut

sub massageRecord {
    my $self     = shift;
    my $tableId  = shift;
    my $recordId = shift;
    my $record   = shift;

    for my $key (keys %$record){
        next unless $key =~ m/_id$/;
        delete $record->{$key};
        last;
    }
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

1;

