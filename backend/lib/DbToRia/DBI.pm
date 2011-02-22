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
    my $type = shift;
    my $dbh	= $self->getDbh();
	my $sth = $dbh->table_info('',$self->schema,'', $type);
	my @tables;
	while ( my $table = $sth->fetchrow_hashref ) {
	    push @tables, {
            id   => $table->{TABLE_NAME},
            name => $table->{REMARKS}
    	}
    }
    return \@tables;
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
	my $pksth = $dbh->primary_key_info(undef, undef, $table);
    while ( my $pk = $pksth->fetchrow_hashref ) {
        $primaryKeys{$pk->{COLUMN_NAME}} = 1;
    }

	# call column_info for metadata on columns
	my $sth = $dbh->column_info(undef, undef, $table, undef);

	my @columns;
	while( my $col = $sth->fetchrow_hashref ) {
        my $id = $col->{column_name};

        # return structure
        push @columns, {
            id         => $id,
            type       => $self->{driver_object}->map_type($col->{TYPE_NAME}),
            nativeType => $col->{TYPE_NAME},
            name       => $col->{REMARKS},
            size       => $col->{COLUMN_SIZE},
            required   => $col->{NULLABLE} == 0,
            references => $foreignKeys{$id},
            primaryKey => $primaryKeys{$id},
            pos        => $col->{ORDINAL_POSITION} 
        }
    }
    # sort the result
    $self->{tableStructure}{$table} = [ sort { $a->{pos} <=> $b->{pos} } @columns ];
    return $self->{tableStructure}{$table};
}

=head2 getTableData(table)

Returns all data from a table. The result can be massive. We only use it for pupulating
selection lists (fk)

=cut

sub getTableData {
    my $self = shift;

    my $table = shift;
    my $selection = shift || {};
    
    my $dbh = $self->getDbh();
	my $query = "SELECT * FROM ". $dbh->quote_identifier($table);
	
    my @where;
    for my $key (keys %$selection) {
        push @where, $dbh->quote_identifier($key) . ' = ' .  $dbh->quote($selection->{$key});
    }
    if (@where){
        $query .= ' WHERE '. join (' AND ',@where);
    }
    my $sth = $dbh->prepare($query);
    $sth->execute;
    my @data;

    my $structure = $self->getTableStructure($table);
    while ( my @row = $sth->fetchrow_array ) {
        my @new_row;
        for (my $i=0;$i<$#row;$i++){
            $new_row[$i] = $self->{driver_obj}->db_to_fe($row[$i],$structure->[$i]->{nativeType});
        }
        push @data,\@new_row;
    }
    return \@data;
}

=head2 getTableDataChunk(table)

Returns all data from a table. The result can be massive. We only use it for pupulating
selection lists (fk) ... should merge this code with getTableData above almost the same!

=cut

sub getTableDataChunk {
    my $self	  = shift;

    my $table = shift;
    my $filter	  = shift;
    my $firstRow  = shift;
    my $lastRow   = shift;
    my $sortId	  = shift;
    my $sortDirection = shift;

    my $dbh = $self->getDbh();

	my $query = 'SELECT * FROM '. $dbh->quote_identifier($table);
	
    my @where;
    for my $key (keys %$filter) {
        my $value = $filter->{$key};
        my $op = $value =~ /%/ ? ' LIKE ' : ' = ';
        push @where, $dbh->quote_identifier($key) . $op . $value;
    }
    $query .= ' WHERE '. join (' AND ',@where) if @where;
	
    $query .= ' ORDER BY ' . $dbh->quote_identifier($sortId) . $sortDirection if $sortId;
	
    $query .= ' LIMIT ' . ($lastRow - $firstRow) . ' OFFSET ' . $firstRow;

    my $sth = $dbh->prepare($query);
    $sth->execute;
    my @data;

    my $structure = $self->getTableStructure($table);
    while ( my @row = $sth->fetchrow_array ) {
        my @new_row;
        for (my $i=0;$i<$#row;$i++){
            $new_row[$i] = $self->{driver_obj}->db_to_fe($row[$i],$structure->[$i]->{nativeType});
        }
        push @data,\@new_row;
    }
    return \@data;
}

=head2 updateTableData(table,selection,data)

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

    my $sth = $dbh->prepare($update);
    
    return $sth->execute();        
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
    my $keyCol = (grep { $_->{primaryKey} } @$structure)[0]->{id};

	return  $dbh->last_insert_id(undef,undef,$table,$keyCol);    
}

=head2 deleteTableData(table,selection)

Insert and return key of new entry

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

    my $sth = $dbh->prepare($delete);
    return $sth->execute();
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
