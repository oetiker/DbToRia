package DbToRia::DBI;

=head1 NAME

DbToRia::DBI - database interface

=head1 SYNOPSIS

 use DbToRia::DBI;
 my $h = DbToRia::DBI->new(dns=>d,user=>u,password=>p);
 my $dbh = $h->getDbh();
 my $tables = $h->getTables();
 my $struct = 

=head1 DESCRIPTION


=cut

use strict;
use DBI;
use DbToRia::Exception;
use Encode;
use Mojo::JSON;

use Mojo::Base -base;

has 'dsn';
has 'username';
has 'password';
has 'schema';
has 'encoding';

sub new {
    my $self = shift->SUPER::new(@_);
    my $driver = (DBI->parse_dsn($self->{dsn}))[1];
    $self->{driver} = $driver;      
    require 'DbToRia/DBI/'.$self->{driver}.'.pm';
    no strict 'refs';
    $self->{driver_object} = "DbToRia::DBI::$self->{driver}"->new();
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
    my $dbh = DBI->connect_cached($self->{dsn},$self->{username},$self->{password},{
        RaiseError => 1,
        PrintError => 0,
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
    return $self->{tableList} if $self->{tableList};
    my $dbh	= $self->getDbh();
	my $sth = $dbh->table_info('',$self->schema,'', 'TABLE,VIEW');
	my @tables;
	while ( my $table = $sth->fetchrow_hashref ) {
        next unless $table->{TABLE_TYPE} ~~ ['TABLE','VIEW'];
	    push @tables, {
            id   => $table->{TABLE_NAME},
            type => $table->{TABLE_TYPE},
            name => $self->fromDb($table->{REMARKS} || $table->{TABLE_NAME})
    	}
    }
    $self->{tableList} = [ sort {$a->{name} cmp $b->{name}} @tables ];
    return $self->{tableList};
}

=head2 getTableStructure(table)

Returns meta information about the table structure directly from he database
This uses the map_type methode from the database driver to map the internal
datatypes to DbToRia compatible datatypes.

=cut

sub getTableStructure {
    my $self = shift;
    my $table = shift;

    return $self->{tableStructure}{$table} if exists $self->{tableStructure}{$table};
    my $dbh = $self->getDbh();
	my $fksth = $dbh->foreign_key_info(undef, undef, undef, undef, undef, $table);

	my %foreignKeys;
    while ( my $fk = $fksth->fetchrow_hashref ) {
        $foreignKeys{$fk->{FK_COLUMN_NAME}} = {
            table => $fk->{UK_TABLE_NAME},
            field => $fk->{UK_COLUMN_NAME}
        };    
    }

    my %primaryKeys;
    my @primaryKey;
	my $pksth = $dbh->primary_key_info(undef, undef, $table);
    while ( my $pk = $pksth->fetchrow_hashref ) {
        $primaryKeys{$pk->{COLUMN_NAME}} = 1;
        push @primaryKey, $pk->{COLUMN_NAME};
    }

	# call column_info for metadata on columns
	my $sth = $dbh->column_info(undef, undef, $table, undef);

	my @columns;
    my %typeMap;
	while( my $col = $sth->fetchrow_hashref ) {
        my $id = $col->{COLUMN_NAME};
        # return structure
        push @columns, {
            id         => $id,
            type       => $self->{driver_object}->map_type($col->{TYPE_NAME}),
            name       => $self->fromDb($col->{REMARKS}),
            size       => $col->{COLUMN_SIZE},
            required   => $col->{NULLABLE} == 0,
            references => $foreignKeys{$id},
            primary    => $primaryKeys{$id},
            pos        => $col->{ORDINAL_POSITION} 
        };
        $typeMap{$id} = $col->{TYPE_NAME};
    }
    # sort the result
    $self->{tableStructure}{$table} = {
        columns => [ sort { $a->{pos} <=> $b->{pos} } @columns ],
        typeMap => \%typeMap,
        meta => {
            primary => \@primaryKey
        }
    };
    return $self->{tableStructure}{$table};
}

=head2 getListView(table)

returns information on how to display the table content in a tabular format

=cut

sub getListView {
    my $self = shift;
    my $tableId = shift;
    my $structure = $self->getTableStructure($tableId);
    my @return;
    for my $row (@{$structure->{columns}}){
        push @return, { map { $_ => $row->{$_} } qw (id type name size) };
    }  
    return \@return;
}

=head2 getEditView(table)

returns information on how to display a single record in the table

=cut

sub getEditView {
    my $self = shift;
    my $table = shift;
    my $tableList = $self->getTableList();
    my $structure = $self->getTableStructure($table);
    my @return;
    for my $row (@{$structure->{columns}}){
        push @return, { map { $_ => $row->{$_} } qw (id type name size pos) };
    }  
    return \@return;
}

=head2 getRecord (table,recordId)

Returns hash of data for the record matching the indicated key. Data gets converted on the way out.

=cut

sub getRecord {
    my $self = shift;
    my $dbh = $self->getDbh();
    my $table = $dbh->quote_identifier(shift);
    my $recordId = $dbh->quote(shift);
    my $primaryKey = $dbh->quote_identifier($self->getTableStructure($table)->{meta}{primary}[0]);
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE $primaryKey = $recordId"); 
    $sth->execute();
    my $row = $sth->fetchrow_hashref;    
    my $structure = $self->getTableStructure($table);
    my $typeMap = $structure->{typeMape};
    my %newRow;
    for my $key (keys %$row) {
          $newRow{$key} = $self->{driver_object}->db_to_fe($self->fromDb($row->{$key}),$typeMap->{$key});
    };
    return \%newRow;
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

sub _buildWhere {
    my $self = shift;
    my $filter = shift or return '';
    my $dbh = $self->getDbh();
    my @where;
    for my $key (keys %$filter) {
        my $value = $filter->{$key}{value};
        my $op = $filter->{$key}{op};
        die error(90732,"Unknown operator '$op'") if not $op ~~ ['==','<','>','like'];
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
    my $sortColumn  = $opts->{sortColumn};
    my $sortDirection = $opts->{sortDesc} ? 'DESC' : 'ASC';
    my $filter = $opts->{filter};

    my $dbh = $self->getDbh();

    my $structure = $self->getTableStructure($table);
    my $typeMap = $structure->{typeMap};
    unshift @$columns, $structure->{meta}{primary}[0];

	my $query = 'SELECT '
        . join(',',map{$dbh->quote_identifier($_)} @$columns)
        . ' FROM '
        . $dbh->quote_identifier($table);
	
    $query .= $self->_buildWhere($filter);
    $query .= ' ORDER BY ' . $dbh->quote_identifier($sortColumn) . $sortDirection if $sortColumn;	
    $query .= ' LIMIT ' . ($lastRow - $firstRow) . ' OFFSET ' . $firstRow;
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my @data;
    while ( my @row = $sth->fetchrow_array ) {
        my @new_row;
        $new_row[0] = [ $row[0], Mojo::JSON::true, Mojo::JSON::true ];
        for (my $i=1;$i<$#row;$i++){
            $new_row[$i] = $self->{driver_object}->db_to_fe($self->fromDb($row[$i]),$typeMap->{$sth->{NAME}[$i]});
        }
        push @data,\@new_row;
    }    
    return \@data
}

=head2 getNumRows(table,filter)

Find the number of rows matching the current filter

=cut

sub getRowCount {
    my $self = shift;
    my $table = shift;
    my $filter = shift;
    
    my $dbh = $self->getDbh();
	my $query = "SELECT COUNT(*) FROM ". $dbh->quote_identifier($table);
	
    $query .= $self->_buildWhere($filter);
    return ($dbh->selectrow_array($query))[0];
}

=head2 updateTableData(table,selection,data)

Update the record with the given recId using the data.

=cut

sub updateTableData {
    my $self	  = shift;    
    my $table     = shift;
    my $recId     = shift;
    my $data	  = shift;

    my $dbh = $self->getDbh();

    my $update = 'UPDATE '.$dbh->quote_identifier($table);
    my $structure = $self->getTableStructure($table);
    my $primaryKey = $structure->{meta}{primary}[0];
    my $typeMap = $structure->{typeMape}; 

    my @set;  
    for my $key (keys %$data) {
        push @set, $dbh->quote_identifier($key) . ' = ' . $dbh->quote($self->toDb($self->{driver_object}->fe_to_db($data->{$key},$typeMap->{$key})));
    }
    $update .= 'SET '.join(', ',@set) if @set;
    
    my @where = ( $dbh->quote_identifier($primaryKey) . ' = ' . $dbh->quote($recId));
    $update .= ' WHERE '. join (' AND ',@where) if @where;

    $dbh->begin_work;
    my $rows = $dbh->do($update);    
    if ($rows > 1){
        $dbh->rollback();
        die error(33874,"Statement $update would affect $rows rows. Rolling back.");
    }
    $dbh->commit;
    return $rows;
}

=head2 insertTableData(table,data)

Insert and return key of new entry

=cut

sub insertTableData {
    my $self	  = shift;
    my $table	  = shift;
    my $data	  = shift;

    my $dbh = $self->getDbh();
    my $insert = 'INSERT INTO '. $dbh->quote_identifier($table);

    my $structure = $self->getTableStructure($table);
    my $primaryKey = $structure->{meta}{primary}[0];
    my $typeMap = $structure->{typeMape};

    my @keys;
    my @values;
    
    for my $key (keys %$data) {
        push @keys, $dbh->quote_identifier($key);
        push @values, $dbh->quote($self->toDb($self->{driver_object}->fe_to_db($data->{$key},$typeMap->{$key})));
    }
    
    $insert .= '('.join(',',@keys).') VALUES ('.join(',',@values).')';
    my $sth = $dbh->prepare($insert);
    
    $sth->execute();
    return $dbh->last_insert_id(undef,undef,$table,$primaryKey);
}

=head2 deleteTableData(table,selection)

Delete matching entries from table.

=cut

sub deleteTableData {
    my $self	  = shift;
    my $table	  = shift;
    my $recId     = shift;

    my $dbh = $self->getDbh();

    my $delete = 'DELETE FROM '. $dbh->quote_identifier($table);

    my $primaryKey = $self->getTableStructure($table)->{meta}{primary}[0];
    my @where = ( $dbh->quote_identifier($primaryKey) . ' = ' . $dbh->quote($recId));
    $delete .= ' WHERE '. join (' AND ',@where) if @where;

    $dbh->begin_work;
    my $rows = $dbh->do($delete);
    if ($rows > 1){
        $dbh->rollback;
        die error(38948,"Statement $delete would affect $rows rows. Rolling back");
    }
    $dbh->commit;
    return $rows;
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
