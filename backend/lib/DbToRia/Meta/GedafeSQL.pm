
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

Pull in information needed prior to using this engine. This function
is called right after the database has been connected.

=cut

sub prepare {
    my $self = shift;

    my $runtime;
    my $start = time();

    # build a name cache for Gedafe from table column column
    # comments (not from views)
    my $tables = $self->DBI->getAllTables();
    $runtime = time()-$start; print STDERR "getAllTables() after $runtime secs\n";
    my %colHash;
    for my $table (keys %$tables) {
        next unless $tables->{$table}{type} eq 'TABLE';
        my $structure = $self->DBI->getTableStructure($table);

        my $columns   = $structure->{columns};
        for my $col (@$columns) {
            $colHash{$col->{id}} = $col->{remark} if $col->{remark};
        }
    }
    $self->{colHash} = \%colHash;
    $runtime = time()-$start; print STDERR "colHash() after $runtime secs\n";
#    use Data::Dumper; print STDERR Dumper "colHash=", \%colHash;

    # replace column names with remarks or cached table column names
    for my $table (keys %$tables) {
        my $structure = $self->DBI->getTableStructure($table);
        $self->massageTableColumns($structure);
    }
    $runtime = time()-$start; print STDERR "prepare finished after $runtime secs\n";
}


=head2 massageTables(tablelist)

Updates the table list created by L<DbToRia::DBI::base::getTables>.
Replace table name with table comment if it exists.

=cut

sub massageTables {
    my $self = shift;
    my $tables = shift;
    for my $table (keys %$tables) {
        if ($tables->{$table}{type} eq 'VIEW' and $table =~ /_(list|combo)$/ ){
            delete $tables->{$table};
            next;
        }
        next unless exists $tables->{$table}{remark};
        $tables->{$table}{name} = $tables->{$table}{remark};
        delete $tables->{$table}{remark};
        if (exists $self->{cfg}{tablenamesReplace} ) {
            my ($match, $replace) = split /,/, $self->{cfg}{tablenamesReplace};
            $tables->{$table}{name} =~ s/$match/$replace/;
        }
    }
}

=head2 massageToolbarTables(tablelist)

Updates the table toolbar list created by
L<DbToRia::DBI::base::getToolbarTables>.

=cut

sub massageToolbarTables {
    my $self = shift;
    my $tables = shift;

    use Data::Dumper; print STDERR Dumper "cfg=", $self->{cfg};
    return $tables unless exists $self->{cfg}{toolbarTables};
    my $i;
    my $regex = $self->{cfg}{toolbarTables};
    my @tbTables;
#    for ($i=0; $i < scalar @$tables; $i++) {
    for my $table (@$tables) {
        next unless $table->{name} =~ m/$regex/;
        push @tbTables, $table;
    }
    my @sortedTables = sort { $a->{name} cmp $b->{name} }  @tbTables;
    if (scalar @sortedTables) {
        $tables = \@sortedTables;
    }
    return $tables;
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
        $structure->{columns}[0]{hidden}  = 1;
        $structure->{meta}{primary} = [ $structure->{columns}[0]{id} ];
        for my $col (@{$structure->{columns}}) {
            $col->{hidden} = 1 if $col->{id} eq 'meta_sort';
        }
        return;
    }
}

=head2 massageTableColumns(tableStructure, colHash)

Replace colum names with remarks or cached table column names in views
if they exist. Based on tableStructure initially created by
L<DbToRia::DBI::base::getTableStructure>.

=cut

sub massageTableColumns {
    my $self      = shift;
    my $structure = shift;

    my $colHash   = $self->{colHash};
    for my $col (@{$structure->{columns}}) {
        my $id = $col->{id};
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
    my $tables = $self->DBI->getAllTables();
    if ($tables->{$view->{tableId}.'_list'}){
        my $newView = $self->DBI->prepListView($view->{tableId}.'_list');
        map { $view->{$_} = $newView->{$_} } keys %$newView;
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
        if (exists $tables->{$row->{tableId}.'_combo'}){
            $row->{tableId} .= '_combo';
            $row->{idCol} = 'id';
            $row->{valueCol} = 'text';
        }
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

