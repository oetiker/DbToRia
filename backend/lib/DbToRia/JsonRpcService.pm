package DbToRia::JsonRpcService;

=head1 NAME

DbToRia::JsonRpcService - RPC Service for DbToRia

=head1 SYNOPSYS

This is used by L<DbToRia::MojoApp> to provide access to DbToRia
server functions

=head1 DESCRIPTION

=cut

use Mojo::Base -base;

has 'cfg';
has 'mojo_stash';
has 'DBI';

use strict;

use DbToRia::DBI;

=head2 new(cfg=>DbToRia::Config)

setup a new serivice

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    $self->DBI(DbToRia::DBI->new(dsn=>$self->cfg->{General}{dsn}));
    return $self;
}

=head2 allow_rpc_access(method)

This gets called before each method call. We use it to make sure the
session settings are correct and users get connected as with their own login.

=cut

our %allow_access = (
    login => 1,
    getTables => 2,
    getViews => 2,
    getTableStructur => 2,
    getTableData => 2,
    getTableDataChunk => 2,
    updateTableData => 2,
    insertTableData => 2,
    deleteTableData => 2,
    getNumRows => 2,
    logout => 1,
);

sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    my $access = $allow_access{$method} or return 0;
    my $session = $self->mojo_stash->{'dbtoria.session'};
    return 1 if $access == 1;
    if ( $access == 2 and $session->param('authenticated') ){
        $self->DBI->username($session->param('username'));
        $self->DBI->password($session->param('password'));
        return 1;
    }
    return 0;
}   

 
sub login {
    my $self = shift;
    my $param = shift;
    my $username = $param->{username};
    my $password = $param->{password};
    my $session = $self->mojo_stash->{'dbtoria.session'};
    $session->param('username',$username);
    $session->param('password',$password);
    $session->param('authenticated',1) if $self->DBI->getDbh->ping;
    return 1;
}



sub getTables {
    my $self = shift;
    return $self->DBI->getTables('TABLE'); 
}

sub getViews{
    my $self = shift;
    return $self->DBI->getTables('VIEW');
}

sub getTableStructure {
    my $self = shift;
    return $self->DBI->getTableStructure(@_); 
}

sub getTableData {
    my $self = shift;
    return $self->DBI->getTableData(@_); 
}

sub getTableDataChunk {
    my $self = shift;
    return $self->DBI->getTableDataChunk(@_); 
}

sub updateTableData {
    my $self = shift;
    return $self->DBI->updateTableData(@_);
}

sub insertTableData{
    my $self = shift;
    return $self->DBI->insertTableData(@_);
}

sub deleteTableData{
    my $self = shift;
    return $self->DBI->deleteTableData(@_);
}

sub getNumRows{
    my $self = shift;
    return $self->DBI->getNumRows(@_);
}


sub logout{
    my $self = shift;
    $self->_mojo_stash->{'dbtoria.session'}->delete();
    return 1;
}


1;

__END__

=back

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
S<Matthias Bloch E<lt>matthias@puffin.chE<gt>>,
S<David Anleitner E<lt>david.angleitner@tet.htwchur.chE<gt>>

=head1 HISTORY

 2011-02-20 to 0.1 rewriten for DBI module

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et

