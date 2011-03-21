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

use Mojo::Base -base;

has 'dsn';
has 'username';
has 'password';
has 'schema';

sub new {
    my $self = shift->SUPER::new(@_);
    my $driver = (DBI->parse_dsn($self->{dsn}))[1];
    $self->{driver} = $driver;      
    require 'DbToRia/DBI/'.$self->{driver}.'.pm';
    no strict 'refs';
    $self->{driver_object} = "DbToRia::DBI::$self->{driver}"->new();
    return $self;
}

    
sub getDbh {
    my $self = shift;
    my $dbh = DBI->connect_cached($self->{dsn},$self->{username},$self->{password},{
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        LongReadLen=> 5*1024*1024,
        pg_enable_utf8=>1
    });
}

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
            name => $table->{REMARKS} || $table->{TABLE_NAME}
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
	while( my $col = $sth->fetchrow_hashref ) {
        my $id = $col->{COLUMN_NAME};
        # return structure
        push @columns, {
            id         => $id,
            type       => $self->{driver_object}->map_type($col->{TYPE_NAME}),
            name       => $col->{REMARKS},
            size       => $col->{COLUMN_SIZE},
            required   => $col->{NULLABLE} == 0,
            references => $foreignKeys{$id},
            primary    => $primaryKey{$id},
            pos        => $col->{ORDINAL_POSITION} 
        }
    }
    # sort the result
    $self->{tableStructure}{$table} = {
        columns => [ sort { $a->{pos} <=> $b->{pos} } @columns ],
        meta => {
            primary => \@primaryKey
        }
    }
    return $self->{tableStructure}{$table};
}

=head2 getListView(table)

returns information on how to display the table content in a tabular format

=cut

sub getListView {
    my $self = shift;
    my $table = shift;
    my $tableList = $self->getTableList();
    my $structure = $self->getTableStructure($table);
    for my $row (@{$structure->{columns}}){
        
    }  
}

=head2 getTableDataChunk(table,firstRow,lastRow,columns,optMap)

Returns the selected columns from the table. Using firstRow and lastRow the number of results can be limited.

The columns argument is an array of column identifiers

The following options are supported:

 sortColumn => name of the column to use for sorting
 sortDesc => sort descending
 filter => { key => [ 'op', 'value'], ... }

The first column of the data returned is always the primary key.

Return format:

 [ [c1,c2,c3,... ],[...], ...]

    
=cut

sub getTableDataChunk {
    my $self	  = shift;
    my $table = shift;
    my $firstRow  = shift;
    my $lastRow   = shift;
    my $columns   = shift;
    my $opts = shift || {};
    my $sortKey  = $opts->{sortColumn};
    my $sortDirection = $opts->{sortDesc} ? 'DESC' : 'ASC';

    my $dbh = $self->getDbh();

	my $query = 'SELECT '
        . join(',',map{$dbh->quote_identifyer($_)} @$columns)
        . ' FROM '
        . $dbh->quote_identifier($table);
	
    my @where;
    for my $key (keys %$filter) {
        my $value = $filter->{$key}{value};
        my $op = $filter->{$key}{op};
        die error(90732,"Unknown operator '$op'") if not $op ~~ ['==','<','>','like'];
        push @where, $dbh->quote_identifier($key) . $op . $value;
    }
    $query .= ' WHERE '. join (' AND ',@where) if @where;	
    $query .= ' ORDER BY ' . $dbh->quote_identifier($sortColumn) . $sortDirection if $sortColumn;	
    $query .= ' LIMIT ' . ($lastRow - $firstRow) . ' OFFSET ' . $firstRow;
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my @data;
    while ( my @row = $sth->fetchrow_array ) {
        my @new_row;
        for (my $i=0;$i<$#row;$i++){
            $new_row[$i] = $self->{driver_object}->db_to_fe($row[$i],$sth->{TYPE}[$i]);
        }
        push @data,\@new_row;
    }    
    return \@data
}

=head2 updateTableData(table,selection,data)

Update the records matching the selection map with data.

=cut

sub updateTableData {

    my $self	  = shift;
    
    my $table = shift;
    my $selection = shift;
    my $data	  = shift;

    my $dbh = $self->getDbh();

    my $update = 'UPDATE '.$dbh->quote_identifier($table);

    my @set;  
    for my $key (keys %$data) {
        push @set, $dbh->quote_identifier($key) . ' = ' . $dbh->quote($data->{$key});
    }
    $update .= 'SET '.join(', ',@set) if @set;
    
    my @where;
      for my $key (keys %$selection) {
        push @where, $dbh->quote_identifier($key) . ' = ' . $dbh->quote($selection->{$key});
    }
    $update .= ' WHERE '. join (' AND ',@where) if @where;

    $dbh->begin_work;
    my $rows = $dbh->do($update);    
    if ($rows > 1){
        $dbh->rollback();
        die error(33874,"Statement $update would affect $rows rows. Rolling back.");
    }
    return $rows;
}

=head2 insertTableData(table,data)

Insert and return key(s) of new entry

=cut

sub insertTableData {
    my $self	  = shift;
    my $table	  = shift;
    my $data	  = shift;

    my $dbh = $self->getDbh();
    my $insert = 'INSERT INTO '. $dbh->quote_identifier($table);

    my @keys;
    my @values;
    
    for my $key (keys %$data) {
        push @keys, $dbh->quote_identifier($key);
        push @values, $dbh->quote($data->{$key});
    }
    
    $insert .= '('.join(',',@keys).') VALUES ('.join(',',@values).')';
    my $sth = $dbh->prepare($insert);
    
    $sth->execute();

    my $structure = $self->getTableStructure($table);

    return $dbh->last_insert_id(undef,undef,$table,$structure->{meta}{primary});    
}

=head2 deleteTableData(table,selection)

Delete matching entries from table.

=cut

sub deleteTableData {
    my $self	  = shift;
    my $table	  = shift;
    my $selection = shift;

    my $dbh = $self->getDbh();

    my $delete = 'DELETE FROM '. $dbh->quote_identifier($table);

    my @where;
      for my $key (keys %$selection) {
        push @where, $dbh->quote_identifier($key) . ' = ' . $dbh->quote($selection->{$key});
    }
    $delete .= ' WHERE '. join (' AND ',@where) if @where;

    $dbh->begin_work;
    my $rows = $dbh->do($delete);
    if ($rows > 1){
        $dbh->rollback();
        die error(38948,"Statement $delete would affect $rows rows. Rolling back");
    }
    $dbh->commit;
    return $rows;
}

=head2 getNumRows(table,filter)

Find the number of rows matching the current filter

=cut

sub getNumRows {
    my $self = shift;

    my $table = shift;
    my $filter = shift || {};
    
    my $dbh = $self->getDbh();
	my $query = "SELECT COUNT(*) FROM ". $dbh->quote_identifier($table);
	
    my @where;
    for my $key (keys %$filter) {
        my $value = $filter->{$key};
        my $op = $value =~ /%/ ? ' LIKE ' : ' = ';
        push @where, $dbh->quote_identifier($key) . $op . $value;
    }
    if (@where){
        $query .= ' WHERE '. join (' AND ',@where);
    }
    return ($dbh->selectrow_array($query))[0];
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
