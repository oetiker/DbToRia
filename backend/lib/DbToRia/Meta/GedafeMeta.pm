package DbToRia::Meta::GedafeMeta;

=head1 NAME

DbToRia::Meta::GedafeMeta - read meta table information gedafe style out of the database

=head1 SYNOPSIS

 use DbToRia::Meta::GedafeMeta

=head1 DESCRIPTION

DbToRia can be used as a drop-in replacement for gedafe. The compatibility
layer for the meta_* tables is reaslized by this module. See L<http://isg.ee.ethz.ch/tools/gedafe/> for details on
Gedafe.

=cut

use strict;
use warnings;
use Encode;
use DbToRia::Exception qw(error);
use Mojo::Base 'DbToRia::Meta::base';
use Mojo::JSON;

has 'metaTables' => sub { {} };
has 'metaFields' => sub { {} };
has 'prepared';

=head2 prepare

after the database is connected, prepare the meta tables. Make sure we do this only once

=cut

sub prepare {
    my $self = shift;
    return if $self->prepared;
    my $tables = $self->DBI->getAllTables();
    if ($tables->{meta_tables}){
        $self->metaTables($self->readMetaTables);
    }
    if ($tables->{meta_fields}){
        $self->metaFields($self->readMetaFields);
    }
    $self->prepared(1);
}

=head2 readMetaTables

Pull in the content of the meta_tables table and make it available in the metaTables
attribute as a hash of arrays:

 table => { 
    attribute => value,
    ...
 }

=cut

sub readMetaTables {
    my $self = shift;
    my $data = $self->DBI->getTableDataChunk('meta_tables',undef,undef,[qw(meta_tables_table meta_tables_attribute meta_tables_value)]);
    my %meta;
    for my $row (@$data){
        $meta{$row->[1]}{$row->[2]} = $row->[3];
    }
    return \%meta;
}

=head2 readMetaFields

Pull in the content of the meta_fields table and make it available in the metaFields attribute as a hash.

=cut

sub readMetaFields {
    my $self = shift;
    my $data = $self->DBI->getTableDataChunk('meta_fields',undef,undef,[qw(meta_fields_table meta_fields_field meta_fields_attribute meta_fields_value)]);
    my %meta;
    for my $row (@$data){
        $meta{$row->[1]}{$row->[2]}{$row->[3]} = $row->[4];
    }
    return \%meta;
}


=head2 massageTables(tablelist)

Updates the table list created by L<DbToRia::DBI::base::getTables>.

=cut

sub massageTables {
    my $self = shift;
    my $tables = shift;
    my $mt = $self->metaTables;
    for my $table (keys %$tables) {
        if ($table =~ /^meta_(fields|tables)$/){
            delete $tables->{$table};
        }
        my $meta = $mt->{$table};
        next unless $meta;
        if ($meta->{hide}){
            delete $tables->{$table};
            next;
        }
    }
}

=head2 massageToolbarTables(tablelist)

Updates the table toolbar list created by L<DbToRia::DBI::base::getToolbarTables>.

=cut

sub massageToolbarTables {
    my $self = shift;
    my $tables = shift;
    my $mt = $self->metaTables;
    my @tbTables;    
    for my $table (@$tables) {
        if ($table->{tableId} !~ /^meta_(fields|tables)$/ and not defined $mt->{$table}{hide} ){
            push @tbTables, $table;
        }
    }
    @$tables = @tbTables;
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

    for my $row (@$editView) {
        my $field = $row->{name};

        # fix field type depending on meta fields entries
        for my $table (keys %{$self->{metaFields}}) {
            next unless exists $self->{metaFields}{$table}{$field}{widget};
            my $widget = $self->{metaFields}{$table}{$field}{widget};
            if ($widget eq 'area') {
                $row->{type} = 'TextArea';
            }
            elsif ($widget eq 'floattime') {
                $row->{type} = 'FloatTimeField';
            }
            elsif ($widget eq 'time') {
                $row->{type} = 'TimeField';
            }
            elsif ($widget eq 'readonly') {
                $row->{readOnly} = $Mojo::JSON::TRUE;
            }
        }
        for my $table (keys %{$self->{metaFields}}) {
            next unless exists $self->{metaFields}{$table}{$field}{copy};
            my $copy   = $self->{metaFields}{$table}{$field}{copy};
            if ($copy) {
                $row->{copyForward} = $Mojo::JSON::TRUE;
            }
        }
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

