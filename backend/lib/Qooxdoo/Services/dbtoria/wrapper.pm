package Qooxdoo::Services::dbtoria::wrapper;

use strict;

use Qooxdoo::JSONRPC;
use DbToRia::Config;
use DbToRia::Logger;
use Data::Dumper;
use CGI;
use CGI::Session;
use CGI::Cookie;

sub getDbHandle() {
    my $config = new DbToRia::Config->getConfig();
    
    # this sucks, better way?
    eval "use DbToRia::Databases::$config->{'db_type'}";
    eval "return new DbToRia::Databases::$config->{'db_type'}";
}

sub method_authenticate
{
    my $params 	= @_;
    my $cgi = new CGI;
    
    # create session with login data for future queries
    my $sid = $cgi->cookie("CGISESSID") || undef;
    my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});


    # if username and password are provided use them instead of session values
    if($params == 3) {
	$session->param("username", $_[1]);
	$session->param("password", $_[2]);
    }
    else {
	push(@_, $session->param("username"));
	push(@_, $session->param("password"));
    }    
    
    return getDbHandle()->authenticate(@_);
}

sub method_getTables
{
    return getDbHandle()->getTables(@_); 
}

sub method_getTableStructure
{
    return getDbHandle()->getTableStructure(@_); 
}

sub method_getTableData
{
    return getDbHandle()->getTableData(@_); 
}

sub method_getTableDataChunk
{
    return getDbHandle()->getTableDataChunk(@_); 
}

sub method_updateTableData
{
    return getDbHandle()->updateTableData(@_);
}

sub method_insertTableData
{
    return getDbHandle()->insertTableData(@_);
}

sub method_deleteTableData
{
    return getDbHandle()->deleteTableData(@_);
}

sub method_getNumRows
{
    return getDbHandle()->getNumRows(@_);
}

sub method_getViews
{
    return getDbHandle()->getViews(@_);
}

sub method_logout
{
    # delete session
    my $cgi = new CGI;
    my $sid = $cgi->cookie("CGISESSID") || undef;
    my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
    
    $session->delete();
}

##############################################################################

=head1 NAME

Qooxdoo::Services::dbtoria:wrapper - Database Wrapper for DbToRia

=head1 SYNOPSIS

This wrapper decides which database specific implementation is called 
upon invocation of one of implemented methods.

For detailed information see api documentation.

=head1 AUTHOR

David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>

=cut


1;
