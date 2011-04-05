package DbToRia::DBI::Pg;

=head1 NAME

DbToRia::DBI::Pg - postgresql support for DbToRia

=head1 SYNOPSIS

 use DbToRia::DBI::Pg
 ...

=head1 DESCRIPTION

All methods from L<DbToRia::DBI::base> implemented for Postgresql.

=head2 mapType(type_name)

Map a native database column type to a DbToRia field type:

 varchar
 integer
 float
 boolean
 datatime

=cut

use Mojo::Base 'DbToRia::DBI::base';
use DbToRia::Exception qw(error);
use Mojo::JSON;
use DBI;


our $map = {
    (map { $_ => 'varchar' } ('bit','bit varying','varbit','character varying','varchar','character','text','char','name')),
    (map { $_ => 'integer' } ('bigint','int8','int','int4','serial','bigserial','smallint','integer')),
    (map { $_ => 'float' }   ('double precision','numeric','decimal','real','float 8','float4')),
    (map { $_ => 'boolean' } ('boolean')),
    (map { $_ => 'datetime' } ('timestamp without time zone')),
    (map { $_ => 'date' } ('date')),
};


sub mapType {
    my $self = shift;
    my $type = shift;
    return $map->{$type} || die error(9844,'Unknown Database Type: "'.$type.'"');
}

   
=head2 getAllTables()

Returns a list of tables and views available from the system.

=cut

sub getAllTables {
    my $self = shift;    
    return $self->{tableList} if $self->{tableList};
    my $dbh	= $self->getDbh();
	my $sth = $dbh->table_info('',$self->schema,'', 'TABLE,VIEW');
	my %tables;
	while ( my $table = $sth->fetchrow_hashref ) {
        next unless $table->{TABLE_TYPE} ~~ ['TABLE','VIEW'];
	    $tables{$table->{TABLE_NAME}} = {
            type => $table->{TABLE_TYPE},
            name => $table->{REMARKS} || $table->{TABLE_NAME}
    	};
    }
    $self->{tableList} = \%tables;
    return $self->{tableList};
}

=head2 getTableStructure(table)

Returns meta information about the table structure directly from he database
This uses the mapType methode from the database driver to map the internal
datatypes to DbToRia compatible datatypes.

=cut

sub getTableStructure {
    my $self = shift;
    my $table = shift;

    return $self->{tableStructure}{$table} if exists $self->{tableStructure}{$table};

    my $dbh = $self->getDbh();
	my %foreignKeys;
    if ( my $fksth = $dbh->foreign_key_info(undef, undef, undef, undef, undef, $table)){
        while ( my $fk = $fksth->fetchrow_hashref ) {
            $foreignKeys{$fk->{FK_COLUMN_NAME}} = {
                table => $fk->{UK_TABLE_NAME},
                column => $fk->{UK_COLUMN_NAME}
            };    
        }
    }
    my %primaryKeys;
    my @primaryKey;
	if ( my $pksth = $dbh->primary_key_info(undef, undef, $table) ){
        while ( my $pk = $pksth->fetchrow_hashref ) {
            $primaryKeys{$pk->{COLUMN_NAME}} = 1;
            push @primaryKey, $pk->{COLUMN_NAME};
        }
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
            type       => $self->mapType($col->{TYPE_NAME}),
            name       => $col->{REMARKS} || $id,
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
    for my $engine (@{$self->metaEngines}){
        $engine->massageTableStructure($table,$self->{tableStructure}{$table});
    }
    return $self->{tableStructure}{$table};
}

=head2 getRecord (table,recordId)

Returns hash of data for the record matching the indicated key. Data gets converted on the way out.

=cut

sub getRecord {
    my $self = shift;
    my $tableId = shift;
    my $dbh = $self->getDbh();
    my $recordId = $dbh->quote(shift);
    my $tableIdQ = $dbh->quote_identifier($tableId);
    my $primaryKey = $dbh->quote_identifier($self->getTableStructure($tableId)->{meta}{primary}[0]);
    my $sth = $dbh->prepare("SELECT * FROM $tableIdQ WHERE $primaryKey = $recordId"); 
    $sth->execute();
    my $row = $sth->fetchrow_hashref;    
    my $structure = $self->getTableStructure($tableId);
    my $typeMap = $structure->{typeMap};
    my %newRow;
    for my $key (keys %$row) {
        $newRow{$key} = $self->dbToFe($row->{$key},$typeMap->{$key});
    };
    return \%newRow;
}

=head2 getForm (table,recordId)

transitional method to get both the form description AND the default data. If the recordId is null, the form will contain
the default values

=cut

sub getForm {
    my $self = shift;
    my $tableId = shift;
    my $recordId = shift;
    my $rec = $self->getRecord($tableId,$recordId);
    my $view = $self->getEditView($tableId);    
    for my $field (@$view){
        if ($field->{type} eq 'ComboTable'){
            my $crec = $self->getRecord($field->{tableId},$rec->{$field->{name}});
            $field->{initialText} = $crec->{$field->{valueCol}};
        }
        $field->{initial} = $rec->{$field->{name}}
    }
    return $view;
}

=head2 getTableDataChunk(table,firstRow,lastRow,columns,optMap)

Returns the selected columns from the table. Using firstRow and lastRow the number of results can be limited.

If firstRow is undefined, the complete table contents will be returned.

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
    unshift @$columns, ( $structure->{meta}{primary}[0] || 'NULL') ;

	my $query = 'SELECT '
        . join(',',map{/^NULL$/ ? 'NULL' : $dbh->quote_identifier($_)} @$columns)
        . ' FROM '
        . $dbh->quote_identifier($table);
	
    $query .= ' '.$self->buildWhere($filter);
    $query .= ' ORDER BY ' . $dbh->quote_identifier($sortColumn) . $sortDirection if $sortColumn;	
    $query .= ' LIMIT ' . ($lastRow - $firstRow + 1) . ' OFFSET ' . $firstRow if defined $firstRow;
    warn $query,"\n";
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my @data;
    while ( my @row = $sth->fetchrow_array ) {
        my @new_row;
        $new_row[0] = [ $row[0], $Mojo::JSON::TRUE, $Mojo::JSON::TRUE ];
        for (my $i=1;$i<=$#row;$i++){
            $new_row[$i] = $self->dbToFe($row[$i],$typeMap->{$sth->{NAME}[$i]});
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
	
    $query .= $self->buildWhere($filter);
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
    my $typeMap = $structure->{typeMap}; 

    my @set;  
    for my $key (keys %$data) {
        push @set, $dbh->quote_identifier($key) . ' = ' . $dbh->quote($self->feToDb($data->{$key},$typeMap->{$key}));
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
    my $typeMap = $structure->{typeMap};

    my @keys;
    my @values;
    
    for my $key (keys %$data) {
        push @keys, $dbh->quote_identifier($key);
        push @values, $dbh->quote($self->feToDb($data->{$key},$typeMap->{$key}));
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

