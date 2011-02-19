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

use base qw(Mojo::Base);

__PACKAGE__->attr('dsn');
__PACKAGE__->attr('user');
__PACKAGE__->attr('password');

sub new {
    my $self = shift->SUPER::new(@_);
    my ($scheme,$driver) = DBI->parse_dsn($self->{dsn});
    $self->{schema} = $schema;
    $self->{driver} = $driver;      
    require 'DbToRia/Driver/'.$self->{driver};
    no strict 'refs';
    $self->{driver} = "DbToRia::Driver::$self->{driver}"->new();
}
    
sub getDbh {
    my $self;
    my $dbh = DBI->connect_cached($self->{dsn},$self->{user},$self->{password},{
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
        ShowErrorStatement => 1,
        FetchHashKeyName=>'NAME_lc',
        LongReadLen=> 5*1024*1024,
        pg_enable_utf8=>1
    });
}

sub getTables {
    my $self = shift;
    my $type = shift || 'TABLE';
    my $dbh	= $self->getDbh();
	my $sth = $db->table_info(undef, $self->{schema}, undef, $type) or die("DB Error" . DBI->errstr);
	my @tables;
	while ( my $table = $sth->fetchrow_hashref ) {
	    push(@tables, {
            id   => $table->{TABLE_NAME},
            name => $table->{REMARKS}
    	}
    }
    return \@tables;
}

=head2 getTableStructur(table)

Returns meta information about the table structure directly from he database
This uses the map_type methode from the database driver to map the internal
datatypes to DbToRia compatible datatypes.

=cut
sub getTableStructure {
    my $self = shift;
    my $tableName = shift;
    my $dbh = $self->getDbh();
	my $fksth = $db->foreign_key_info(undef, undef, undef, undef, $self->{schema}, $tableName);

	my %foreignKeys;
    while ( my $fk = $fksth->fetchrow_hashref ) {
        $foreinKeys{$fk->{FK_COLUMN_NAME}} = {
            table => $fk->{UK_TABLE_NAME},
            field => $fk->{UK_COLUMN_NAME}
        };    
    }

    my %primaryKeys;
	my $pksth = $db->primary_key_info(undef, $self->{schema}, $tableName);
    while ( my $pk = $pksth->fetchrow_hashref ) {
        $primaryKeys{$fk->{COLUMN_NAME} = 1;
    }

	# call column_info for metadata on columns
	my $sth = $db->column_info(undef, $schema, $tableName, undef);

	my @columns;
	while( my $col = $sth->fetchrow_hashref ) {
        my $id = $col->{COLUMN_NAME};

        # return structure
        push @columns, {
            id         => $id,
            type       => $self->{driver}->map_type($col->{TYPE_NAME}),
            name       => $column->{REMARKS},
            size       => $column->{COLUMN_SIZE},
            required   => $column->{NULLABLE} == 0,
            references => $foreignKeys{$id},
            primaryKey => $primaryKeys{$id},
            pos        => $col->{ORDINAL_POSITION} || 0
        }
    }
    # sort the result
    return [ sort { $a->{pos} <=> $b->{pos} } @columns ];
}

=head2 getTableData(table)

Returns all data from a table. The result can be massive. We only use it for pupulating
selection lists (fk)

=cut

sub getTableData {
    my $self = shift;

    my $tableName = shift;
    my $selection = shift || {};
    
    my $dbh = $self->getDbh();
	my $query = "SELECT * FROM ". $dbh->quote_identifier($tableName);
	
    my @where;
    for my $key (keys %$selection) {
        push @where, $dbh->quote_identifier($key) . ' = '  $dbh->quote($selection->{$key});
    }
    if (@where){
        $query .= ' WHERE '. join (' AND ',@where);
    }
	my $data = $sth->selectall_arrayref($query);

	
	# call column_info for metadata on columns
	$sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error" . DBI->errstr);
	
	my $index = 0;
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {
	    
	    if($column->{TYPE_NAME} eq "boolean" || $column->{TYPE_NAME} eq "bool") {
		foreach my $row (@$data) {
		    
		    # TODO add additional possible values
		    if($$row[$index] == "1") {
			$$row[$index] = "true";
		    }
		    else{
			$$row[$index] = "false";    
		    }
		}
	    }
	    
	    if($column->{TYPE_NAME} eq "timestamp without time zone") {
		foreach my $row (@$data) {
		    
		    if($$row[$index] =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/) {
			my $year = $1;
			my $month = $2;
			my $day = $3;
			
			my $hour = $4;
			my $minute = $5;
			my $second = $6;

			#$$row[$column->{ORDINAL_POSITION} - 1] = "$day.$month.$year $hour:$minute:$second";
			$$row[$index] = "$day.$month.$year";
		    }
		}
	    }
	    
	    $index++;
	}
	    
	if ($db->errstr) {
	    die($db->errstr);
	}
	
	return {
	    messageType => "answer",
	    data => [@$data]
	};
        
	$db->disconnect;
    }
    else {
	return {
	    messageType => "error",
	    message => DBI->errstr
	};
    }
}

sub getTableDataChunk
{
    my $this	  = shift;
    my $error 	  = shift;
    
    my $tableName = shift;
    my $filter	  = shift;
    my $firstRow  = shift;
    my $lastRow   = shift;
    my $sortId	  = shift;
    my $sortDirection = shift;
    
    my $db 	  = $this->connect();
    
    if($db) {
	my $query = "SELECT * FROM \"" . $tableName . "\"";
	
	if($filter) {
	    $query .= " WHERE";
	    
	    foreach my $row (@$filter) {
		for my $key (keys %$row) {
		    $query .= " \"" . $key . "\" LIKE '" . $row->{$key} . "' AND";
		}
	    }
	    
	    $query = substr($query, 0, length($query) - 4);
	}
	
	if($sortId) {
	    $query .= " ORDER BY \"" . $sortId . "\" " . $sortDirection;
	}
	
	$query .= " LIMIT " . ($lastRow - $firstRow) . " OFFSET " . $firstRow;
	
	DbToRia::Logger->write($query, "Statement");

	my $sth = $db->prepare($query);
	$sth->execute();

	my $data = $sth->fetchall_arrayref;
	
	# call column_info for metadata on columns
	$sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error" . DBI->errstr);
	
	my $index = 0;
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {

	    if($column->{TYPE_NAME} eq "boolean" || $column->{TYPE_NAME} eq "bool") {
		foreach my $row (@$data) {
		    
		    # TODO add additional possible values
		    if($$row[$index] == "1") {
			$$row[$index] = "true";
		    }
		    else{
			$$row[$index] = "false";    
		    }
		}
	    }
	    
	    if($column->{TYPE_NAME} eq "timestamp without time zone") {
		foreach my $row (@$data) {
		    
		    if($$row[$index] =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})$/) {
			my $year = $1;
			my $month = $2;
			my $day = $3;
			
			my $hour = $4;
			my $minute = $5;
			my $second = $6;

			#$$row[$column->{ORDINAL_POSITION} - 1] = "$day.$month.$year $hour:$minute:$second";
			$$row[$index] = "$day.$month.$year";
		    }
		}
	    }
	    
	    $index++;
	}

	if ($db->errstr) {
	    die($db->errstr);
	}
	
	return {
	    messageType => "answer",
	    data => [@$data]
	};
        
	$db->disconnect;
    }
    else {
	return {
	    messageType => "error",
	    message => DBI->errstr
	};
    }
}

sub updateTableData
{

    my $this	  = shift;
    my $error 	  = shift;
    
    my $table	  = shift;
    my $selection = shift;
    my $data	  = shift;

    my $db 	  = $this->connect();

    my $str = "UPDATE \"$table\" SET ";
    
    for my $key (keys %$data) {
	$str .= " \"$key\" = '" . $data->{$key} . "', ";
    }
    
    $str = substr($str, 0, length($str) - 2);
    $str .= " WHERE ";
    
    for my $key (keys %$selection) {
	$str .= " \"$key\" = '" . $selection->{$key} . "' AND ";
    }
    
    $str = substr($str, 0, length($str) - 4);

    my $sth = $db->prepare($str);
    
    $sth->execute();
    
    DbToRia::Logger->write($str, "Statement");
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /TODOsyntax error at or near (.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$1];
	}
	else {
	    $errorMessage = $db->errstr;
	}
       
	return {
	    messageType => "error",
	    message => $errorMessage,
	    params => @params
	}
    }
}

sub insertTableData
{

    my $this	  = shift;
    my $error 	  = shift;
    
    my $table	  = shift;
    my $data	  = shift;

    my $db 	  = $this->connect();

    my $str = "INSERT INTO \"$table\" (";
    
    my $str1;
    my $str2;
    
    for my $key (keys %$data) {
	$str1 .= "\"$key\", ";
	$str2 .= "'" . $data->{$key} . "', ";
    }
    
    $str1 = substr($str1, 0, length($str1) - 2);
    $str2 = substr($str2, 0, length($str2) - 2);
    
    $str .= $str1 . ") VALUES (" . $str2 . ")";
    
    my $sth = $db->prepare($str);
    
    $sth->execute();
    
    DbToRia::Logger->write($str, "Statement");
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	
	if($db->errstr =~ /TODOerror at or near "(.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$1];
	}
	else {
	    $errorMessage = $db->errstr 
	}
       
	return {
	    messageType => "error",
	    message => $errorMessage,
	    params => @params
	}
    }
}

sub deleteTableData
{
    my $this	  = shift;
    my $error 	  = shift;
    
    my $table	  = shift;
    my $selection = shift;

    my $db 	  = $this->connect();

    my $str = "DELETE FROM \"$table\" WHERE ";
    
    for my $key (keys %$selection) {
	$str .= "\"$key\" = '" . $selection->{$key} . "' AND ";
    }
    
    $str = substr($str, 0, length($str) - 4);
    
    my $sth = $db->prepare($str);
    
    $sth->execute();
    
    DbToRia::Logger->write($str, "Statement");
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /TODOyntax error at or near "(.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$1];
	}
	else {
	    $errorMessage = $db->errstr
	}
       
	return {
	    messageType => "error",
	    message => $errorMessage,
	    params => @params
	}
    }
}

sub getNumRows
{
    my $this	  = shift;
    my $error 	  = shift;
    
    my $table	  = shift;
    my $filter	  = shift;
    
    my $db 	  = $this->connect();

    my $str = "SELECT COUNT(*) FROM \"$table\"";
    
    if($filter) {
	$str .= " WHERE";
	
	foreach my $row (@$filter) {
	    for my $key (keys %$row) {
		$str .= " \"" . $key . "\" LIKE '" . $row->{$key} . "' AND";
	    }
	}
	
	$str = substr($str, 0, length($str) - 4);
    }
    
    my $sth = $db->prepare($str);
    my $numRows = 0;

    DbToRia::Logger->write($str, "Statement");

    $sth->execute();
    
    my @column = $sth->fetchrow_array;
    $numRows = $column[0];
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    numRows => $numRows
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /TODOyntax error at or near "(.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$1];
	}
	else {
	    $errorMessage = $db->errstr
	}
       
	return {
	    messageType => "error",
	    message => $errorMessage,
	    params => @params
	}
    }
}

1;

##############################################################################

=head1 NAME

DbToRia::Databases::PostgreSQL.pm - PostgreSQL module for DbToRia

=head1 SYNOPSIS

This database module provides the PostgreSQL specific implementation for 
functions used by DbToRIA.

For detailed information see api documentation.

=head1 AUTHOR

David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>

=cut

