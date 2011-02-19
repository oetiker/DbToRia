package DbToRia::JsonRpcService;

use base qw(Mojo::Base);

__PACKAGE__->attr('cfg');
__PACKAGE__->attr('_mojo_stash');

use strict;

use DbToRia::Config;

sub new{
    my $class = shift;
    
    my $object = {
        
    };
    bless $object, $class;
    return $object;
}

sub authenticate{
    my $params 	= @_;
     
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

    
    return _getDbHandle()->authenticate(@_);
}

sub getTables{
    return _getDbHandle()->getTables(@_); 
}

sub getTableStructure{
    return _getDbHandle()->getTableStructure(@_); 
}

sub getTableData{
    return _getDbHandle()->getTableData(@_); 
}

sub getTableDataChunk{
    return _getDbHandle()->getTableDataChunk(@_); 
}

sub updateTableData{
    return _getDbHandle()->updateTableData(@_);
}

sub insertTableData{
    return _getDbHandle()->insertTableData(@_);
}

sub deleteTableData{
    return _getDbHandle()->deleteTableData(@_);
}

sub getNumRows{
    return _getDbHandle()->getNumRows(@_);
}

sub getViews{
    return _getDbHandle()->getViews(@_);
}

sub logout{
    # delete session
    my $cgi = new CGI;
    my $sid = $cgi->cookie("CGISESSID") || undef;
    my $session = new CGI::Session(undef, $sid, {Directory=>'/tmp'});
    
    $session->delete();
}





# private:
sub _getDbHandle(){
    my $config = new DbToRia::Config->getConfig();
    
    # this sucks, better way?
    eval "use DbToRia::Databases::$config->{'db_type'}";
    eval "return new DbToRia::Databases::$config->{'db_type'}";
    
    # TODO unbedingt $@ behandeln!
}
 
1;
