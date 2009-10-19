package DbToRia::Databases::SQLite;

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
    
    # if database handle does not exist create new connection
    if (!exists $this->{dbh}) {
	my $config = new DbToRia::Config->getConfig();
	
	# establish connection to database specified in config file
	my $dbh = DBI->connect("DBI:SQLite:dbname=$config->{'db_path'}", "", "") or return 0;
	$this->{dbh} = $dbh;
    }
    
    return $this->{dbh};
}

sub authenticate
{
    my $this	= shift;
    my $error 	= shift;
    
    my $db = $this->connect();
    my $config = new DbToRia::Config->getConfig();
    
    # if database connection established we are ready to go
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
	
	if(DBI->errstr =~ /unable to open database file.*/) {
	    $errorMessage = "UnknownDatabase";
	    @params = [$config->{'db_path'}];
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
	my $sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error: '" . DBI->errstr . "'");
	
	# get a list of all primary keys
	my $sth_pk = $db->primary_key_info(undef, undef, $tableName);
	
	# create primary key information hash
	my %primaryKeys;
	while(my $pk = $sth_pk->fetchrow_hashref) {
	    $primaryKeys{$pk->{'COLUMN_NAME'}} = 1;
	}
	
	#DbToRia::Logger->write(Dumper(\%primaryKeys), "PK: ");
	
	# for each column create a hash with the needed information
	while(my $column = $sth->fetchrow_hashref) {

	    # sqlite is typeless so we use varchar for all columns
	    $column->{TYPE_NAME} = "varchar";
	    
	    # get column information
	    my %tmpColumn;
	    $tmpColumn{id} 	= $column->{COLUMN_NAME};
	    $tmpColumn{type}	= $column->{TYPE_NAME};
	    
	    if($primaryKeys{$tmpColumn{id}} == 1) {
		$tmpColumn{primaryKey} = 1;
	    }
	    
	    # order array according to position in database
	    push(@columnsArray, \%tmpColumn);
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

sub getTableData
{
    my $this	  = shift;
    my $error 	  = shift;
    my $tableName = shift;
    
    my $db 	  = $this->connect();
    
    if($db) {
	my $sth = $db->prepare("SELECT * FROM " . $tableName);
	
	if($sth) {
	    $sth->execute();
	
	    my $data = $sth->fetchall_arrayref;
	    
	    # call column_info for metadata on columns
	    $sth = $db->column_info(undef, undef, $tableName, undef) or die("DB Error" . DBI->errstr);
	    
	    return {
		messageType => "answer",
		data => [@$data]
	    };
	}
	
	if ($db->errstr) {
	    my $errorMessage;
	    my @params;
	    
	    if($db->errstr =~ /[^"]*"([^"]*)": syntax error/) {
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

    DbToRia::Logger->write($str, "Statement: ");
    my $sth = $db->prepare($str);

    if($sth) {
	$sth->execute();
	
	return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    
    if ($db->errstr) {
	my $errorMessage;
	my @params;
	
	if($db->errstr =~ /[^"]*"([^"]*)": syntax error/) {
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

sub insertTableData
{

    my $this	  = shift;
    my $error 	  = shift;
    
    my $table	  = shift;
    my $data	  = shift;

    my $db 	  = $this->connect();

    my $str = "INSERT INTO $table (";
    
    my $str1;
    my $str2;
    
    for my $key (keys %$data) {
	$str1 .= "$key, ";
	$str2 .= "'" . $data->{$key} . "', ";
    }
    
    $str1 = substr($str1, 0, length($str1) - 2);
    $str2 = substr($str2, 0, length($str2) - 2);
    
    $str .= $str1 . ") VALUES (" . $str2 . ")";
    
    DbToRia::Logger->write($str, "Statement: ");
    my $sth = $db->prepare($str);

    if($sth) {
	$sth->execute();
	
	return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    
    if ($db->errstr) {
	my $errorMessage;
	my @params;
	
	if($db->errstr =~ /[^"]*"([^"]*)": syntax error/) {
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

    my $str = "DELETE FROM $table WHERE ";
    
    for my $key (keys %$selection) {
	$str .= " `$key` = '" . $selection->{$key} . "' AND ";
    }
    
    $str = substr($str, 0, length($str) - 4);

    DbToRia::Logger->write($str, "Statement: ");
    my $sth = $db->prepare($str);

    if($sth) {
	$sth->execute();
	
	return {
	    messageType => "answer",
	    message => "ok"
	}
    }
    
    if ($db->errstr) {
	my $errorMessage;
	my @params;
	
	if($db->errstr =~ /[^"]*"([^"]*)": syntax error/) {
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

DbToRia::SQLite.pm - SQLite module for DbToRia

=head1 SYNOPSIS

This database module provides the PostgreSQL specific implementation for 
functions used by DbToRIA.

For detailed information see api documentation.

=head1 AUTHOR

David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>

=cut

