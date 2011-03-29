package DbToRia::DBI::base;


=head1 NAME

DbToRia::DBI::base - base class for database drivers

=head1 SYNOPSIS

 use Mojo::Base 'DbToRia::DBI::base';
 ...

=head1 DESCRIPTION

DbToRia uses DBI for database introspection wherever possible. For the non
generic bits it uses the services of a database driver module. This is the base class for
implementing such driver modules.

A driver module must implement the following methods:

=cut

use strict;
use warnings;
use Encode;
use DbToRia::Exception qw(error);
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

has 'dsn';
has 'username';
has 'password';
has 'schema';
has 'encoding';

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{encoder} = find_encoding($self->encoding) if $self->encoding;
    return $self;
}


sub fromDb {
    my $self = shift;
    my $data = shift;
    my $encoder = $self->{encoder};
    if (defined $data and defined $encoder){
        $data = $encoder->decode($data);
    }
    return $data;
}

sub toDb {
    my $self = shift;
    my $data = shift;
    my $encoder = $self->{encoder};
    if (defined $data and defined $encoder){
        $data = $encoder->encode($data);
    }
    return $data;
}    
    
sub getDbh {
    my $self = shift;
    my $driver = (DBI->parse_dsn($self->dsn))[1];
    return DBI->connect_cached($self->dsn,$self->username,$self->password,{
        RaiseError => 0,
        PrintError => 0,
        HandleError => sub {
            my ($msg,$h,$ret) = @_;
            die error($driver."_".$h->state,$h->errstr." (".$h->{Statement}.")");
        },
        AutoCommit => 1,
        ShowErrorStatement => 1,
        LongReadLen=> 5*1024*1024,
    });
}


=head2 getTables()

Returns a list of tables and views available from the system.

=cut

sub getTables {
    my $self = shift;    
    die "Override in Driver";
    return $self->{tableList};
}

=head2 getTableStructure(table)

Returns meta information about the table structure directly from he database
This uses the map_type methode from the database driver to map the internal
datatypes to DbToRia compatible datatypes.

=cut

sub getTableStructure {
    my $self = shift;
    my $tableId = shift;
    die "Override in Driver";
}

=head2 getListView(table)

returns information on how to display the table content in a tabular format

=cut

sub getListView {
    my $self = shift;
    my $tableId = shift;
    die "Override in Driver";
}

=head2 getEditView(table)

returns information on how to display a single record in the table

=cut

sub getEditView {
    my $self = shift;
    my $tableId = shift;
    die "Override in Driver";
}

=head2 getRecord (table,recordId)

Returns hash of data for the record matching the indicated key. Data gets converted on the way out.

=cut

sub getRecord {
    my $self = shift;
    my $tableId = shift;
    my $recordId = shift;
    die "Override in Driver";
}

=head2 getForm (table,recordId)

transitional method to get both the form description AND the default data. If the recordId is null, the form will contain
the default values

=cut

sub getForm {
    my $self = shift;
    my $tableId = shift;
    my $recordId = shift;
    die "Override in Driver";
}

=head2 getTableDataChunk(table,firstRow,lastRow,columns,optMap)

Returns the selected columns from the table. Using firstRow and lastRow the number of results can be limited.

The columns argument is an array of column identifiers

The following options are supported:

 sortColumn => name of the column to use for sorting
 sortDesc => sort descending
 filter => { column => [ 'op', 'value'], ... }

Return format:

 [
   [ [id,update,del], c1,c2,c3,... ],
   [ [], ... ],
   [ ... ]

    
=cut

sub buildWhere {
    my $self = shift;
    my $filter = shift or return '';
    my $dbh = $self->getDbh();
    my @where;
    for my $key (keys %$filter) {
        my $value = $filter->{$key}{value};
        my $op = $filter->{$key}{op};
        die error(90732,"Unknown operator '$op'") if not $op ~~ ['==','<','>','like','ilike'];
        push @where, $dbh->quote_identifier($key) . $op . $dbh->quote($value);
    }
    return 'WHERE '. join(' AND ',@where);
}

sub getTableDataChunk {
    my $self	  = shift;
    my $table     = shift;
    my $firstRow  = shift;
    my $lastRow   = shift;
    my $columns   = shift;
    my $opts = shift || {};
    die "Override in Driver";
}

=head2 getRowCount(table,filter)

Find the number of rows matching the current filter

=cut

sub getRowCount {
    my $self = shift;
    my $table = shift;
    my $filter = shift;
    die "Override in Driver";
}

=head2 updateTableData(table,selection,data)

Update the record with the given recId using the data.

=cut

sub updateTableData {
    my $self	  = shift;    
    my $tableId     = shift;
    my $recordId     = shift;
    my $data	  = shift;
    die "Override in Driver";
}

=head2 insertTableData(table,data)

Insert and return key of new entry

=cut

sub insertTableData {
    my $self	  = shift;
    my $tableId	  = shift;
    my $data	  = shift;
    die "Override in Driver";
}

=head2 deleteTableData(table,selection)

Delete matching entries from table.

=cut

sub deleteTableData {
    my $self	  = shift;
    my $tableId	  = shift;
    my $recordId     = shift;
    die "Override in Driver";
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
S<David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>> (Original PostgreSQL module)

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

1;

