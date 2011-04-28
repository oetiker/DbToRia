
package DbToRia::Meta::GedafeSQL;

=head1 NAME

DbToRia::Meta::Gedafe - read nameing information gedafe style out of the database structure

=head1 SYNOPSIS

 use DbToRia::Meta::GedafeSQL

=head1 DESCRIPTION

DbToRia can be used as a drop-in replacement for gedafe. The compatibility
layer for Gedafe SQL nameing conventions is reaslized by this module. See L<http://isg.ee.ethz.ch/tools/gedafe/> for details on
Gedafe.

=cut

use strict;
use warnings;
use Encode;
use DbToRia::Exception qw(error);
use Mojo::Base 'DbToRia::Meta::base';


=head2 massageMenu(tablelist)

Updates the table list created by L<DbToRia::DBI::base::getTables>.

=cut

sub massageTables {
    my $self = shift;
    my $tables = shift;
    for my $table (keys %$tables) {
        if ($tables->{$table}{type} eq 'VIEW' and $table =~ /_(list|combo)$/ ){
            delete $tables->{$table};
            next;
        }
    }    
}

=head2 massageTableStructure(tableId,tableStructure)

Updates the tableStructure initially created by L<DbToRia::DBI::base::getTableStructure>.

=cut

sub massageTableStructure {
    my $self = shift;
    my $tableId = shift;
    my $structure = shift;
    if ($tableId =~ /_(combo|list)$/){
        $structure->{columns}[0]{primary} = 1;
        $structure->{columns}[0]{hidden} = 1;        
        $structure->{meta}{primary} = [ $structure->{columns}[0]{id} ];
        for (@{$structure->{columns}}){
            $_->{hidden} = 1 if $_->{name} eq 'meta_sort';
        }
    }
} 

=head2 massageListView(tableId,listView) 

Updates the information on how to display the table content in a tabular format

=cut

sub massageListView {
    my $self = shift;
    my $view = shift;
    my $tables = $self->DBI->getAllTables();
    if ($tables->{$view->{tableId}.'_list'}){
        my $newView = $self->DBI->prepListView($view->{tableId}.'_list');
        map { $view->{$_} = $newView->{$_} } keys %$newView;
    }
}

=head2 massageEditView(tableId,editView)

Updates the information on how to display a single record for editing.

=cut

sub massageEditView {
    my $self = shift;
    my $tableId = shift;
    my $editView = shift;
    my $tables = $self->DBI->getAllTables();
    for my $row (@$editView){
        next unless $row->{type} eq 'ComboTable';
        if (exists $tables->{$row->{tableId}.'_combo'}){
            $row->{tableId} .= '_combo';
            $row->{idCol} = 'id';
            $row->{valueCol} = 'text';
        }
    }
    for (my $i=0; $i<scalar @$editView; $i++) {
        my $row = $editView->[$i];
        if ($row->{name} =~ m/_id$/) {
            splice @$editView, $i, 1;
            last;
        }
    }
}


=head2 massageRecord(tableId, recordId, record)

Updates the information that is returned to the backend for a single
record.

=cut

sub massageRecord {
    my $self     = shift;
    my $tableId  = shift;
    my $recordId = shift;
    my $record   = shift;

    for my $key (keys %$record){
        next unless $key =~ m/_id$/;
        delete $record->{$key};
        last;
    }
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

=head1 HISTORY

 2011-03-30 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:

1;

