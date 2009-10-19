package DbToRia::Databases::PostgreSQL;

use strict;

use DBI;
use Qooxdoo::JSONRPC;
use Data::Dumper;
  
my $singleton;

sub new {
    my $class = shift;
    $singleton ||= bless {}, $class;
}

sub connect {
    my $params = @_;
    my $this = shift;
    
    my $username;
    my $password;

    # if username and password are provided try these, otherwise fallback to
    # session values
    if($params == 3) {
	$username = shift;
	$password = shift;
    }
    else {
	my $cgi = new CGI;
	my $sid = $cgi->cookie("CGISESSID") || undef;
	my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
	
	$username = $session->param("username");
	$password = $session->param("password");
    }    
    
    # if database handle does not exist create new connection
    if (!exists $this->{dbh}) {
	my $config = new DbToRia::Config->getConfig();
	
	# establish connection with database and host from config file
	my $dbh = DBI->connect("DBI:Pg:database=$config->{'database'};host=$config->{'host'}", $username, $password) or return 0;
	$this->{dbh} = $dbh;
    }
    
    return $this->{dbh};
}

sub authenticate
{
    my $this	= shift;
    my $error 	= shift;
    
    my $username 	= shift;
    my $password 	= shift;  
    
    my $db = $this->connect($username, $password);
    
    # if database connection established username and password are good
    if($db) {
	return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    
    # otherwise create error object and return error message
    else {
	my $errorMessage = "";
	my @params;
	
	if(DBI->errstr =~ /role "([^"]*)" does not exist/) {
	    $errorMessage = "UnknownUser";
	    @params = [$1];
	}
	elsif (DBI->errstr =~ /database "([^"]*)" does not exist/) {
	    $errorMessage = "UnknownDatabase";
	    @params = [$1]
	}
	elsif (DBI->errstr =~ /no password supplied/) {
	    $errorMessage = "NoPasswordSupplied";
	}
	elsif (DBI->errstr =~ /password authentication failed/) {
	    $errorMessage = "WrongPassword";
	}
	else {
	    $errorMessage = DBI->errstr
	}
       
	return {
	    messageType => "error",
	    message => $errorMessage,
	    params => @params
	};
    }
}

sub getTables
{  
    my @params 	= @_;
    
    my $this	= shift;
    my $db 	= $this->connect();

    if($db) {
	
	my $sth = $db->table_info(undef, "public", undef, "TABLE") or die("DB Error" . DBI->errstr);
	
	my @tables;
	while(my $table = $sth->fetchrow_hashref) {
	    
	    # somehow some columns (apparently those with camelCase) are enclosed in quotes
	    $table->{TABLE_NAME} =~ s/"//g;
	    
	    my %tmpTable;
	    $tmpTable{id} 	= $table->{TABLE_NAME};
	    $tmpTable{name} 	= $table->{REMARKS};
	    
	    push(@tables, \%tmpTable);
	}
	
	#DbToRia::Logger->write(Dumper(@tables), "TABLES");
	
	return {
	    messageType => "answer",
	    tables => [@tables]
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

sub getViews
{  
    my @params 	= @_;
    
    my $this	= shift;
    my $db 	= $this->connect();

    if($db) {
	
	my $sth = $db->table_info(undef, "public", undef, "VIEW") or die("DB Error" . DBI->errstr);
	
	my @tables;
	while(my $table = $sth->fetchrow_hashref) {
	    
	    # somehow some columns (apparently those with camelCase) are enclosed in quotes
	    $table->{TABLE_NAME} =~ s/"//g;
	    
	    my %tmpTable;
	    $tmpTable{id} 	= $table->{TABLE_NAME};
	    $tmpTable{name} 	= $table->{REMARKS};
	    
	    push(@tables, \%tmpTable);
	}
	
	#DbToRia::Logger->write(Dumper(@tables), "TABLES");
	
	return {
	    messageType => "answer",
	    tables => [@tables]
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

sub getTableStructure
{
    my $this	  = shift;
    my $error 	  = shift;
    
    my $tableName = shift;
    my $db 	  = $this->connect();
    
    if($db) {
	
	my $config = new DbToRia::Config->getConfig();
	
	# the array holding all column information which is finally sent to client
	my @columnsArray;
	
	# call column_info for metadata on columns
	my $sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error" . DBI->errstr);
		
	# get a list of all primary keys
	my $sth_pk = $db->primary_key_info(undef, undef, $tableName);
	
	# get a list of all foreign keys
	my $sth_fk = $db->foreign_key_info(undef, undef, undef, undef, undef, $tableName);

	# create foreign key information hash
	my %foreignKeys;
	if($sth_fk) {
	    while(my $fk = $sth_fk->fetchrow_hashref) {
		my %tmpFk;
		
		$fk->{UK_COLUMN_NAME} =~ s/"//g;
		$fk->{FK_COLUMN_NAME} =~ s/"//g;
		
		$tmpFk{'table'} = $fk->{'UK_TABLE_NAME'};
		$tmpFk{'field'} = $fk->{'UK_COLUMN_NAME'};
		
		$foreignKeys{$fk->{'FK_COLUMN_NAME'}} = \%tmpFk;
	    }
	}
	
	# create primary key information hash
	my %primaryKeys;
	if($sth_pk) {
	    while(my $pk = $sth_pk->fetchrow_hashref) {
		$pk->{COLUMN_NAME} =~ s/"//g;
		$primaryKeys{$pk->{'COLUMN_NAME'}} = 1;
	    }
	}
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {

	    # convert postgresql type description to dbtoria format
	    if(	    $column->{TYPE_NAME} eq "bit"               ||
		    $column->{TYPE_NAME} eq "bit varying"       ||
		    $column->{TYPE_NAME} eq "varbit"            ||
		    $column->{TYPE_NAME} eq "character varying" ||
		    $column->{TYPE_NAME} eq "varchar"           ||
		    $column->{TYPE_NAME} eq "character"         ||
		    $column->{TYPE_NAME} eq "char")
	    {
		$column->{TYPE_NAME} = "varchar";
	    }
	    
	    elsif(  $column->{TYPE_NAME} eq "bigint"    ||
		    $column->{TYPE_NAME} eq "int8"      ||
		    $column->{TYPE_NAME} eq "int"       ||
		    $column->{TYPE_NAME} eq "int4"      ||
		    $column->{TYPE_NAME} eq "serial"    ||
		    $column->{TYPE_NAME} eq "bigserial" ||
		    $column->{TYPE_NAME} eq "smallint" )
	    {
		$column->{TYPE_NAME} = "integer";
	    }
	    
	    elsif(  $column->{TYPE_NAME} eq "double precision"  ||
		    $column->{TYPE_NAME} eq "numeric"      	||
		    $column->{TYPE_NAME} eq "decimal"           ||
		    $column->{TYPE_NAME} eq "real"              ||
		    $column->{TYPE_NAME} eq "float4"            ||
		    $column->{TYPE_NAME} eq "float 8" )
	    {
		$column->{TYPE_NAME} = "float";
	    }
	    
	    elsif($column->{TYPE_NAME} eq "bool") {
		$column->{TYPE_NAME} = "boolean";
	    }
	    
	    elsif($column->{TYPE_NAME} eq "timestamp without time zone") {
		$column->{TYPE_NAME} = "datetime";
	    }

# TODO: date types
=cut	    
date	 	calendar date (year, month, day)
time [ (p) ] [ without time zone ]	 	time of day
time [ (p) ] with time zone	timetz	time of day, including time zone
timestamp [ (p) ] [ without time zone ]	timestamp	date and time
timestamp [ (p) ] with time zone	timestamptz	date and time, including time zone
=cut	    

	    my %tmpColumn;
	    
	    # somehow some columns (apparently those with camelCase) are enclosed in quotes
	    $column->{COLUMN_NAME} =~ s/"//g;
	    
	    $tmpColumn{id} 	= $column->{COLUMN_NAME};
	    $tmpColumn{name} 	= $column->{REMARKS};
	    $tmpColumn{type}	= lc($column->{TYPE_NAME});
	    $tmpColumn{size}	= $column->{COLUMN_SIZE};
	    
	    if($foreignKeys{$tmpColumn{id}}) {
		$tmpColumn{references} = $foreignKeys{$tmpColumn{id}};
	    }
	    
	    if($primaryKeys{$tmpColumn{id}} == 1) {
		$tmpColumn{primaryKey} = 1;
	    }
	    
	    # DbToRia::Logger->write(Dumper($column), 2);
	    
	    # order array according to position in database
	    $columnsArray[$column->{ORDINAL_POSITION} - 1] = \%tmpColumn;
	}
	
	# clean the array from null values originated from the hard
	# positioning with ORDINAL_POSITION in the columnsArray 
	my @columnsArrayClean;
	for(@columnsArray) {
	    if ($_) {
		push (@columnsArrayClean, $_);
	    }
	}
	
	if ($db->errstr) {
	    die($db->errstr);
	}
	
	return {
	    messageType => "answer",
	    structure => [@columnsArrayClean]
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

# currently only used with selection because otherwise all
# records are returned, for normal data retrieval getTableDataChunk
# is used
sub getTableData
{
    my $this	  = shift;
    my $error 	  = shift;
    
    my $tableName = shift;
    my $selection = shift;
    
    my $db 	  = $this->connect();
    
    if($db) {
	my $query;
	
	if($selection) {
	    $query = "SELECT * FROM \"" . $tableName . "\" WHERE ";
	     
	    for my $key (keys %$selection) {
		$query .= " \"$key\" = '" . $selection->{$key} . "' AND ";
	    }
	    
	    $query = substr($query, 0, length($query) - 4);
	}
	else {
	    $query = "SELECT * FROM \"" . $tableName . "\"";
	}
	
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

