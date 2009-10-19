package DbToRia::Databases::MySQL;

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
	my $dbh = DBI->connect("DBI:mysql:database=$config->{'database'};host=$config->{'host'}", $username, $password) or return 0;
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
	
	if(DBI->errstr =~ /Unknown database '([^']*)'/) {
	    $errorMessage = "UnknownDatabase";
	    @params = [$1];
	}
	elsif(DBI->errstr =~ /Access denied for user/) {
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
    my $this	= shift;
    my $db 	= $this->connect();
  
    if($db) {
	
	my $sth = $db->table_info(undef, undef, undef, "TABLE") or die("DB Error" . DBI->errstr);

	my @tables;
	while(my $table = $sth->fetchrow_hashref) {
	    my %tmpTable;
	    $tmpTable{id} 	= $table->{TABLE_NAME};
	    $tmpTable{name} 	= $table->{REMARKS};
	    
	    push(@tables, \%tmpTable);
	}
	
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
	
	my $sth = $db->table_info(undef, undef, undef, "VIEW") or die("DB Error" . DBI->errstr);
	
	my @tables;
	while(my $table = $sth->fetchrow_hashref) {	    
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
	my $sth_fk = $db->foreign_key_info(undef, undef, undef, undef, $config->{'database'}, $tableName);
	
	# create foreign key information hash
	my %foreignKeys;
	while(my $fk = $sth_fk->fetchrow_hashref) {
	    
	    # $db->foreign_key_info contains local keys too, only use the ones which contain a foreign table
	    if($fk->{'PKTABLE_NAME'}) {
		my %tmpFk;
		
		$tmpFk{'table'} = $fk->{'PKTABLE_NAME'};
		$tmpFk{'field'} = $fk->{'PKCOLUMN_NAME'};
		
		$foreignKeys{$fk->{'FKCOLUMN_NAME'}} = \%tmpFk;
	    }
	}
	
	# create primary key information hash
	my %primaryKeys;
	while(my $pk = $sth_pk->fetchrow_hashref) {
	    $primaryKeys{$pk->{'COLUMN_NAME'}} = 1;
	}
	
	#DbToRia::Logger->write(Dumper(\%primaryKeys), "PK: ");
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {
	    
	    # convert mysql type description to dbtoria format
	    if($column->{TYPE_NAME} eq "TINYINT") {
		$column->{TYPE_NAME} = "boolean";
	    }
	    
	    if($column->{TYPE_NAME} eq "INT" || $column->{TYPE_NAME} eq "SMALLINT") {
		$column->{TYPE_NAME} = "integer";
	    }
	    
	    if($column->{TYPE_NAME} eq "MEDIUMTEXT" || $column->{TYPE_NAME} eq "LARGETEXT") {
		$column->{TYPE_NAME} = "text";
	    }
	    
	    # get column information
	    my %tmpColumn;
	    $tmpColumn{id} 	= $column->{COLUMN_NAME};
	    $tmpColumn{name} 	= $column->{REMARKS};
	    $tmpColumn{type}	= lc($column->{TYPE_NAME});
	    $tmpColumn{size}	= $column->{COLUMN_SIZE};
	    $tmpColumn{options} = $column->{mysql_values};
	    
	    if($foreignKeys{$tmpColumn{id}}) {
		$tmpColumn{references} = $foreignKeys{$tmpColumn{id}};
	    }
	    
	    if($primaryKeys{$tmpColumn{id}} == 1) {
		$tmpColumn{primaryKey} = 1;
	    }
	    
	    # order array according to position in database
	    $columnsArray[$column->{ORDINAL_POSITION} - 1] = \%tmpColumn;
	}
	
	if ($db->errstr) {
	    die($db->errstr);
	}
	
	return {
	    messageType => "answer",
	    structure => [@columnsArray]
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
	    $query = "SELECT * FROM $tableName WHERE ";
	     
	    for my $key (keys %$selection) {
		$query .= " $key = '" . $selection->{$key} . "' AND ";
	    }
	    
	    $query = substr($query, 0, length($query) - 4);
	}
	else {
	    $query = "SELECT * FROM $tableName ";
	}
	
	DbToRia::Logger->write($query, "Statement");
	
	my $sth = $db->prepare($query);
	$sth->execute();
	
	my $data = $sth->fetchall_arrayref;
	
	# call column_info for metadata on columns
	$sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error" . DBI->errstr);
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {
	    
	    if($column->{TYPE_NAME} eq "TINYINT") {
		foreach my $row (@$data) {
		    if($$row[$column->{ORDINAL_POSITION} - 1] == 1) {
			$$row[$column->{ORDINAL_POSITION} - 1] = "true";
		    }
		    else{
			$$row[$column->{ORDINAL_POSITION} - 1] = "false";    
		    }
		}
	    }
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
	my $query = "SELECT * FROM $tableName ";
	
	if($filter) {
	    $query .= " WHERE";
	    
	    foreach my $row (@$filter) {
		for my $key (keys %$row) {
		    $query .= " " . $key . " LIKE '" . $row->{$key} . "' AND";
		}
	    }
	    
	    $query = substr($query, 0, length($query) - 4);
	}
	
	if($sortId) {
	    $query .= " ORDER BY " . $sortId . " " . $sortDirection;
	}
	
	$query .= " LIMIT " . ($lastRow - $firstRow) . " OFFSET " . $firstRow;
	
	DbToRia::Logger->write($query, "Statement");

	my $sth = $db->prepare($query);
	$sth->execute();

	my $data = $sth->fetchall_arrayref;

	# call column_info for metadata on columns
	$sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error" . DBI->errstr);
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {
	    
	    if($column->{TYPE_NAME} eq "TINYINT") {
		foreach my $row (@$data) {
		    if($$row[$column->{ORDINAL_POSITION} - 1] == 1) {
			$$row[$column->{ORDINAL_POSITION} - 1] = "true";
		    }
		    else{
			$$row[$column->{ORDINAL_POSITION} - 1] = "false";    
		    }
		}
	    }
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

    my $str = "UPDATE $table SET ";
    
    for my $key (keys %$data) {
	$str .= " `$key` = '" . $data->{$key} . "', ";
    }
    
    $str = substr($str, 0, length($str) - 2);
    $str .= " WHERE ";
    
    for my $key (keys %$selection) {
	$str .= " `$key` = '" . $selection->{$key} . "' AND ";
    }
    
    $str = substr($str, 0, length($str) - 4);
    $str .= " LIMIT 1";
    
    my $sth = $db->prepare($str);
    
    $sth->execute();
    
    DbToRia::Logger->write($str, "Statement: ");
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /You have an error in your SQL syntax; (.*) near '(.*)' at line (.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$2];
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

sub insertTableData
{

    my $this	  = shift;
    my $error 	  = shift;
    
    my $table	  = shift;
    my $data	  = shift;

    my $db 	  = $this->connect();

    my $str = "INSERT INTO $table SET ";
    
    for my $key (keys %$data) {
	$str .= " `$key` = '" . $data->{$key} . "', ";
    }
    
    $str = substr($str, 0, length($str) - 2);
    
    my $sth = $db->prepare($str);
    
    $sth->execute();
    
    DbToRia::Logger->write($str, "Statement: ");
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /You have an error in your SQL syntax; (.*) near '(.*)' at line (.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$2];
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

    my $str = "DELETE FROM $table WHERE ";
    
    for my $key (keys %$selection) {
	$str .= " `$key` = '" . $selection->{$key} . "' AND ";
    }
    
    $str = substr($str, 0, length($str) - 4);
    
    my $sth = $db->prepare($str);
    
    $sth->execute();
    
    DbToRia::Logger->write($str, "Statement: ");
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /You have an error in your SQL syntax; (.*) near '(.*)' at line (.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$2];
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

    my $str = "SELECT COUNT(*) FROM $table";
    
    if($filter) {
	$str .= " WHERE";
	
	foreach my $row (@$filter) {
	    for my $key (keys %$row) {
		$str .= " $key LIKE '" . $row->{$key} . "' AND ";
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
    
    DbToRia::Logger->write($str, "NumRows: " . $numRows);
    
    if (!$db->errstr) {
        return {
	    messageType => "answer",
	    numRows => $numRows
	}
    }
    else {
	my $errorMessage = "";
	my @params;
	
	if($db->errstr =~ /You have an error in your SQL syntax; (.*) near '(.*)' at line (.*)/) {
	    $errorMessage = "SyntaxError";
	    @params = [$2];
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

DbToRia::MySQL.pm - MySQL module for DbToRia

=head1 SYNOPSIS

This database module provides the PostgreSQL specific implementation for 
functions used by DbToRIA.

For detailed information see api documentation.

=head1 AUTHOR

David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>

=cut

