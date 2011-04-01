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
has 'log';
has 'DBI';
has 'metaEngines' => sub { [] };

use strict;

use DBI;
use Try::Tiny;

=head2 new(cfg=>DbToRia::Config)

setup a new serivice

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    my $dsn = $self->cfg->{General}{dsn};
    my $driver = (DBI->parse_dsn($dsn))[1];
    require 'DbToRia/DBI/'.$driver.'.pm';
    do { 
        no strict 'refs';
        $self->DBI("DbToRia::DBI::$driver"->new(
            schema=>$self->cfg->{General}{schema},
            dsn=>$dsn,
            metaEnginesCfg => $self->cfg->{MetaEngines}
        ));
    };
    return $self;
}

=head2 allow_rpc_access(method)

This is called before each method call. We use it to make sure the
session settings are correct and users are connected with their own login.

=cut

our %allow_access = (
    login => 1,
    logout => 1,
    getTables => 2,
    getListView => 2,
    getEditView => 2,
    getRecord => 2,
    getForm => 2,
    getTableStructure => 2,
    getRowCount => 2,
    getTableDataChunk => 2,
    updateTableData => 2,
    insertTableData => 2,
    deleteTableData => 2,
);

sub connect_db {
    my $self = shift;
    my $session = $self->mojo_stash->{'dbtoria.session'};
    my $dbi = $self->DBI;
    $dbi->username($session->param('username'));
    $dbi->password($session->param('password'));
    return try {
        $dbi->getDbh->ping;
        for my $engine (@{$self->metaEngines}){
            $engine->prepare();
        }
        return 1;
    }
    catch {
        $self->log->warn($_);
        return 0;
    }
}

sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    my $access = $allow_access{$method} or return 0;
    return ( $access == 1 or ( $access == 2 and $self->connect_db() ) ) ? 1 : 0
}   

=head1 login({username=>u,password=>p})

On successful login, return 1, else return an exception.

=cut
 
sub login {
    my $self = shift;
    my $param = shift;
    my $username = $param->{username};
    my $password = $param->{password};
    my $session = $self->mojo_stash->{'dbtoria.session'};
    $session->param('username',$username);
    $session->param('password',$password);
    my $connect = $self->connect_db;
    return $connect;
}

sub logout{
    my $self = shift;
    $self->mojo_stash->{'dbtoria.session'}->delete();
    return 1;
}

sub getTables {
    my $self = shift;
    return $self->DBI->getTables(@_);
}

sub getListView {
    my $self = shift;
    return $self->DBI->getListView(@_);
}

sub getEditView {
    my $self = shift;
    return $self->DBI->getEditView(@_);
}

sub getRecord {
    my $self = shift;
    return $self->DBI->getRecord(@_);
}

sub getForm {
    my $self = shift;
    return $self->DBI->getForm(@_);
}

sub getTableDataChunk {
    my $self = shift;
    return $self->DBI->getTableDataChunk(@_); 
}

sub getRowCount {
    my $self = shift;
    return $self->DBI->getRowCount(@_);
}

sub updateTableData {
    my $self = shift;
    return $self->DBI->updateTableData(@_);
}

sub insertTableData {
    my $self = shift;
    return $self->DBI->insertTableData(@_);
}

sub deleteTableData {
    my $self = shift;
    return $self->DBI->deleteTableData(@_);
}

sub getTableStructure {
    my $self = shift;
    return $self->DBI->getTableStructure(@_);
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

