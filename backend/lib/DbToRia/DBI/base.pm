package DbToRia::DBI::base;


=head1 NAME

DbToRia::DBI::base - base class for database drivers

=head1 SYNOPSIS

 use Mojo::Base 'DbToRia::DBI::base';
 ...

=head1 DESCRIPTION

DbToRia uses DBI for database introspection wherever possible. For the
non generic bits it uses the services of a database driver
module. This is the base class for implementing such driver modules.

A driver module must implement the following methods:

=cut

# use 5.12.1;
use strict;
use warnings;

use DbToRia::Exception qw(error);
use Storable qw(dclone);
use Mojo::Base -base;

has 'dsn';
has 'encoding';
has 'username';
has 'password';
has 'schema';
has 'metaEngines';
has 'metaEnginesCfg' => sub { {} };
has 'dbhCache' => sub { {} };

sub new {
    my $self = shift->SUPER::new(@_);
    my $meta = $self->metaEnginesCfg;
    my @metaEngines;
    for my $engine (keys %$meta){
        require 'DbToRia/Meta/'.$engine.'.pm';
        do {
            no strict 'refs';
            push @metaEngines, "DbToRia::Meta::$engine"->new(cfg=>$meta->{$engine},DBI=>$self);
        };
    }
    $self->metaEngines(\@metaEngines);
    return $self;
}

=head1 ABSTRACT METHODS

=head2 getTableDataChunk(table,firstRow,lastRow,columns,optMap)

Returns the selected columns from the table. Using firstRow and
lastRow the number of results can be limited.

The columns argument is an array of column identifiers

The following options are supported:

 sortColumn => name of the column to use for sorting
 sortDesc => sort descending
 filter => { column => [ 'op', 'value'], ... }

Return format:

 [
   [ [id,update,del], c1,c2,c3,... ],
   [ [], ... ],
   [ ... ]


=cut

sub getTableDataChunk {
    my $self	  = shift;
    my $table     = shift;
    my $firstRow  = shift;
    my $lastRow   = shift;
    my $columns   = shift;
    my $opts = shift || {};
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 getRowCount(table,filter)

Find the number of rows matching the current filter

=cut

sub getRowCount {
    my $self = shift;
    my $table = shift;
    my $filter = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 updateTableData(table,selection,data)

Update the record with the given recId using the data.

=cut

sub updateTableData {
    my $self	  = shift;
    my $tableId     = shift;
    my $recordId     = shift;
    my $data	  = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 insertTableData(table,data)

Insert and return key of new entry

=cut

sub insertTableData {
    my $self	  = shift;
    my $tableId	  = shift;
    my $data	  = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 deleteTableData(table,selection)

Delete matching entries from table.

=cut

sub deleteTableData {
    my $self	  = shift;
    my $tableId	  = shift;
    my $recordId     = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head1 CORE METHODS

=head2 getDbh

returns a database handle. The method reconnects as required.

=cut

sub getDbh {
    my $self = shift;
    my $driver = (DBI->parse_dsn($self->dsn))[1];
    my $key    = ($self->username||'???').($self->password||'???');
    my $dbh    = $self->dbhCache->{$key};
    my $utf8   = ($self->encoding eq 'utf8');
    if (not defined $dbh){
        $self->dbhCache->{$key} = $dbh = DBI->connect($self->dsn,$self->username,$self->password,{
            RaiseError => 0,
            PrintError => 0,
            HandleError => sub {
                my ($msg,$h,$ret) = @_;
                my $state = $h->state || 9999;
                my $code = lc($state);
                $code =~ s/[^a-z0-9]//g;
                $code =~ s/([a-z])/sprintf("%02d",ord($1)-97)/eg;
                $code += 70000000;
                delete $self->dbhCache->{$key};
                die error($code,$h->errstr. ( $h->{Statement} ? " (".$h->{Statement}.") ":'')." [${driver}-$state]");
            },
            AutoCommit => 1,
            ShowErrorStatement => 1,
            LongReadLen=> 5*1024*1024,
        });
    }
    return $dbh;
}


=head2 getAllTables()

Returns a map of tables with associated meta information.

=cut

sub getAllTables {
    my $self = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
    return $self->{tableList};
}

=head2 getToolbarTables()

Returns an array of tables to display in toolbar.

=cut

sub getToolbarTables {
    my $self = shift;
    my $tables = $self->getAllTables();
    my @tableArray;
    for my $table (keys %$tables) {
        next unless $tables->{$table}{type} eq 'TABLE';
        my $item = {
            tableId => $table,
            name => $tables->{$table}{name},
            remark => $tables->{$table}{remark},
            readOnly => $tables->{$table}{readOnly},
        };
        push @tableArray, $item;
    }
    my $ta = \@tableArray;
    for my $engine (@{$self->metaEngines}){
        $engine->massageToolbarTables($ta);
    }    
    return $ta;
}

=head2 getTableStructureRaw(table)

Returns meta information about the table structure directly from he database
This uses the map_type methode from the database driver to map the internal
datatypes to DbToRia compatible datatypes.

=cut

sub getTableStructureRaw {
    my $self = shift;
    my $tableId = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 getTableStructure(table)

Returns meta information about the table structure directly from he database
This uses the map_type methode from the database driver to map the internal
datatypes to DbToRia compatible datatypes.

=cut

sub getTableStructure {
    my $self = shift;
    my $tableId = shift;
    my $struct = dclone($self->getTableStructureRaw($tableId));
    for my $engine (@{$self->metaEngines}){
        $engine->massageTableStructure($tableId, $struct);
    }
    return $struct;
}


=head2 getTablePrivileged(table)

Returns permission information about the table for the current user.

=cut

sub getTablePrivileges {
    my $self = shift;
    my $table = shift;
    return {
        UPDATE => 1,
        INSERT => 1,
        DELETE => 1,
        SELECT => 1
    };
}

=head2 getRecord (table,recordId)

Returns hash of data for the record matching the indicated key. Data
gets converted on the way out.

=cut

sub getRecord {
    my $self = shift;
    my $tableId = shift;
    my $recordId = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 getRecordDeref (table,recordId)

Returns hash of data for the record matching the indicated key with
foreign key references resolved.

=cut

sub getRecordDeref {
    my $self     = shift;
    my $tableId  = shift;
    my $recordId = shift;

    my $rec  = $self->getRecord($tableId, $recordId);

    # resolve foreign key references
    my $view = $self->getEditView($tableId);
    for my $field (@$view){
        if ($field->{type} eq 'ComboTable'){
            my $key      = $field->{name};
            $rec->{$key} = $self->getRecord($field->{tableId}, $rec->{$key});
        }
    }
    return $rec;
}


=head2 getReferencedRecord (tableId, recordId, columnId)

Returns hash of data for the dataset referenced by the record matching
the indicated record and column keys with foreign key references
resolved.

=cut

sub getReferencedRecord {
    my $self     = shift;
    my $params   = shift;
    my $tableId  = $params->{tableId};
    my $recordId = $params->{recordId};
    my $columnId = $params->{columnId};

    my $fTableId;
    my $fKeyId;
    # resolve foreign key references
    my $ts = $self->getTableStructure($tableId);
    for my $col (@{$ts->{columns}}) {
        if ($col->{id} eq $columnId) {
            $fTableId = $col->{references}{table};
            $fKeyId   = $col->{references}{column};
            last;
        }
    }
    return undef unless defined $fTableId;

    my $fKeyVal  = $self->getRecord($tableId, $recordId)->{$columnId};

    my $fts = $self->getTableStructure($fTableId);
    my $fPkId = $fts->{meta}{primary}[0];

    my $dbh = $self->getDbh();
    my $query = "SELECT $fPkId FROM $fTableId ";
    $query .= ' '.$self->buildWhere([{field  => $fKeyId,
                                      value1 => $fKeyVal,
                                      op     => '=',
                                     }]);
    my $sth = $dbh->prepare($query);
    $sth->execute;

    my $fPkVal = $sth->fetchrow_hashref()->{$fPkId};
    my $fRec = $self->getRecordDeref($fTableId, $fPkVal);
    my $view = $self->getEditView($fTableId);
    for my $field (@$view){
        if (exists $fRec->{$field->{name}}) {
            $fRec->{$field->{label}} = $fRec->{$field->{name}};
            delete $fRec->{$field->{name}};
        }
    }
    return $fRec;
}


=head2 getDefaults (table)

Returns hash of columns with default values.

=cut

sub getDefaults {
    my $self = shift;
    my $tableId = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 getDefaultsDeref (table)

Returns hash of columns with default values with
foreign key references resolved.

=cut

sub getDefaultsDeref {
    my $self     = shift;
    my $tableId  = shift;

    my $rec  = $self->getDefaults($tableId);
    # resolve foreign key references
    my $view = $self->getEditView($tableId);
    for my $field (@$view){
        if ($field->{type} eq 'ComboTable'){
            my $key      = $field->{name};
            next unless exists $rec->{$key}; # only fields already there
            $rec->{$key} = $self->getRecord($field->{tableId}, $rec->{$key});
        }
    }
    return $rec;
}


=head1 BASE METHODS

=head2 getDatabaseName

Return name of the database connected to.

=cut

sub getDatabaseName {
    my $self = shift;
    die error(654, (caller(0))[3] . ' must be overwritten in driver');
}

=head2 getTables

Return tables and views filtered for menu display.

=cut

sub getTables {
    my $self = shift;
    my $tables = dclone($self->getAllTables(@_));
    for my $engine (@{$self->metaEngines}){
        $engine->massageTables($tables);
    }
    return $tables;
}

=head2 getListView(table)

Returns information on how to display the table content in a tabular
format.

=cut

sub prepListView {
    my $self = shift;
    my $tableId = shift;
    my $structure = $self->getTableStructure($tableId);
    my @return;
    for my $row (@{$structure->{columns}}){
        next if $row->{hidden};
	my $fk = defined $row->{references} ? $Mojo::JSON::TRUE : $Mojo::JSON::FALSE;
	$row->{fk} = $fk;
        push @return, { map { $_ => $row->{$_} } qw (id type name size fk) };
    };
    return {
        tableId => $tableId,
        columns => \@return
    };
}

sub getListView {
    my $self = shift;
    my $tableId = shift;
    my $view = $self->prepListView($tableId);
    for my $engine (@{$self->metaEngines}){
        $engine->massageListView($view);
    }
    return $view;
}

=head2 getEditView(table)

returns information on how to display a single record in the table

=cut

sub getEditView {
    my $self = shift;
    my $tableId = shift;
    my $structure = $self->getTableStructure($tableId);
    my $tables = $self->getAllTables();
    my @return;
    my $widgetMap = {
        varchar => 'TextField',
        integer => 'IntField',
        float   => 'FloatField',
        time    => 'TimeField',
        date    => 'Date',
        boolean => 'CheckBox',
    };

    for my $col (@{$structure->{columns}}){
        my $c = {
           name  => $col->{id},
           label => $col->{name},
        };
        # can never edit a primary key
        $c->{readOnly} = $Mojo::JSON::TRUE if $col->{primary};
        # tell the FE we have a primary key
        $c->{primaryKey} = $col->{primary} ? $Mojo::JSON::TRUE : $Mojo::JSON::FALSE;
        $c->{required} = $col->{required};
        $c->{check} = $col->{check};
        if ($col->{references}){
            $c->{type}     = 'ComboTable';
            $c->{tableId}  = $col->{references}{table},
            $c->{idCol}    = $col->{references}{column},
            my $rstruct    = $self->getTableStructure($c->{tableId});
            $c->{valueCol} = ${$rstruct->{columns}}[1]{id}; # show value in col 1 in ComboBox
        }
        else {
            $c->{type} = $widgetMap->{$col->{type}} || die { code=>2843, message=>"No Widget for Field Type: $col->{type}"};
        }
        push @return,$c;
    }
    for my $engine (@{$self->metaEngines}){
        $engine->massageEditView($tableId,\@return);
    }
    return \@return;
}


=head2 getForm (table,recordId)

Transitional method to get both the form description AND the default
data. If recordId is null, the form will contain the default values.

=cut

sub getForm {
    my $self = shift;
    my $tableId = shift;
    my $recordId = shift;
    my $rec = $self->getRecord($tableId,$recordId); # data
    my $view = $self->getEditView($tableId);        # form
    for my $field (@$view){
        if ($field->{type} eq 'ComboTable'){
            my $crec = $self->getRecord($field->{tableId},$rec->{$field->{name}});
            $field->{initialText} = $crec->{$field->{valueCol}};
        }
        $field->{initial} = $rec->{$field->{name}}
    }
    return $view;
}

=head2 getFilterOpsArray()

Return an array of DBMS specific comparison operators to be used in filtering.

The following operators are available in PostgreSQL, SQLite, and MySQL.

=cut

sub getFilterOpsArray {
    my $self = shift;
    return [{op   => '=',                    type => 'simpleValue', help => 'equal'},
            {op   => '!=',                   type => 'simpleValue', help => 'not equal'},
            {op   => '<',                    type => 'simpleValue', help => 'less than'},
            {op   => '>',                    type => 'simpleValue', help => 'greater than'},
            {op   => '<=',                   type => 'simpleValue', help => 'less or equal'},
            {op   => '>=',                   type => 'simpleValue', help => 'greater or equal'},
            {op   => 'IS NULL',              type => 'noValue',     help => 'value not defined'},
            {op   => 'IS NOT NULL',          type => 'noValue',     help => 'value defined'},

            {op   => 'LIKE',                 type => 'simpleValue',
             help => 'substring matching with wildcards'},
            {op   => 'NOT LIKE',             type => 'simpleValue',
             help => 'substring matching with wildcards'},

            {op   => 'IN',                   type => 'simpleValue', help => 'contained in list'},
            {op   => 'NOT IN',               type => 'simpleValue', help => 'contained in list'},

            # 'IS TRUE', 'IS NOT TRUE',
            # 'IS FALSE', 'IS NOT FALSE',

           ];
}


=head2 getFilterOpsHash()

Return a hash of DBMS specific comparison operators to be used in
filtering. This hash is built from a call to getFilterOpsArray() and
cached.

=cut

our %filterOpsHash;

sub getFilterOpsHash {
    my $self = shift;
    if (not defined $self->{filterOpsHash}) {
        for my $opHash (@{$self->getFilterOpsArray()}) {
            my $op = $opHash->{op};
            $self->{filterOpsHash}{$op} = $opHash->{type};
        }
    }
    return $self->{filterOpsHash};
}


=head2 buildWhere(filter)

create a where fragment based on a filter map and array of the form

 {
    key => ['op', 'value' ],
 }

=cut

sub buildWhere {
    my $self = shift;
    my $filter = shift or return '';
    my $dbh = $self->getDbh();
    my @wheres;
    my $filterOpsHash = $self->getFilterOpsHash();
    for my $f (@$filter) {
        my $field  = $f->{field};
        my $value1 = $f->{value1};
        my $value2 = $f->{value2};
        my $op     = $f->{op};
        my $type   = $filterOpsHash->{$op};
        die error(90732,"Unknown operator '$op'") if not exists $filterOpsHash->{$op};
        my $where;
        if ($type eq 'noValue') {
            $where = $dbh->quote_identifier($field) ." $op ";
        }
        elsif ($type eq 'simpleValue') {
            $where = $dbh->quote_identifier($field) ." $op ". $dbh->quote($value1);
        }
        elsif ($type eq 'dualValue') {
            $where = $dbh->quote_identifier($field) ." $op ". $dbh->quote($value1)
                                                    ." AND ". $dbh->quote($value2);
        }
        else {
            die error(90733,"Operator type '$type' not supported.");
        }
        push @wheres, $where;
    }
    return 'WHERE '. join(' AND ',@wheres);
}

=head2 map_type(type_name)

Map a native database column type to a DbToRia field type:

 varchar
 integer
 float
 boolean
 datatime

=cut

sub mapType {
    my $self = shift;
    return "varchar";
}

=head2 dbToFe(value,type)

Convert the data returned from an sql query to something suitable for
the frontend according to the database type.

=cut

sub dbToFe {
    my $self  = shift;
    my $value = shift;
    my $type  = shift;
    my $ourtype = $self->mapType($type);
    if ($ourtype eq 'boolean' and defined $value){
        $value = int($value) ? $Mojo::JSON::TRUE : $Mojo::JSON::FALSE;
    }
    return $value;
}

=head2 feToDb(value,type)

Convert the data from the frontend to a format usable in sql.

=cut

sub feToDb {
    my $self = shift;
    my $value = shift;
    my $type = shift;
    my $ourtype = $self->mapType($type);
    if ($ourtype eq 'boolean'){
        $value = $value ? 1 : 0;
    }
    return $value;
}

1;

__END__

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
S<David Angleitner E<lt>david.angleitner@tet.htwchur.chE<gt>> (Original PostgreSQL module)

=head1 HISTORY

 2011-02-20 to 1.0 first version

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

