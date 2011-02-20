package DbToRia::JsonRpcService;

use base qw(Mojo::Base);

__PACKAGE__->attr('cfg');
__PACKAGE__->attr('_mojo_stash');
__PACKAGE__->attr('DBI');

use strict;

use DbToRia::DBI;

=head2 _check_access(method)

This gets called before each method call .. we can use it to make sure the
session settings are correct and users get connected as themselfes to the
database.

=cut

sub _check_access {
    my $self = shift;
    my $method = shift;
    if ($self->DBI){
        $self->DBI()->session($self->_mojo_stash->{'dbtoria.session'});
    }
}   

 
sub authenticate {
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $session = $self->_mojo_stash->{'dbtoria.session'};
    $session->param('username',$username);
    $session->param('password',$password);
    $self->DBI(DbToRia::DBI->new(dsn=>$self->cfg->{General}{dsn}));    
}

sub getTables {
    my $self = shift;
    return $self->DBI()->getTables('TABLE'); 
}

sub getViews{
    my $self = shift;
    return $self->DBI()->getTables('VIEW');
}

sub getTableStructure {
    my $self = shift;
    return $self->DBI()->getTableStructure(@_); 
}

sub getTableData {
    my $self = shift;
    return $self->DBI()->getTableData(@_); 
}

sub getTableDataChunk {
    my $self = shift;
    return $self->DBI()->getTableDataChunk(@_); 
}

sub updateTableData {
    my $self = shift;
    return $self->DBI()->updateTableData(@_);
}

sub insertTableData{
    my $self = shift;
    return $self->DBI()->insertTableData(@_);
}

sub deleteTableData{
    my $self = shift;
    return $self->DBI()->deleteTableData(@_);
}

sub getNumRows{
    my $self = shift;
    return $self->DBI()->getNumRows(@_);
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

