package DbToRia::DBI::SQLite;

=head1 NAME

DbToRia::DBI::Pg - SQLite support for DbToRia

=head1 SYNOPSIS

 use DbToRia::DBI::SQLite
 ...

=head1 DESCRIPTION

All methods from L<DbToRia::DBI::base> implemented for SQLite.

=head2 mapType(type_name)

Map a native database column type to a DbToRia field type:

 varchar
 integer
 float
 boolean
 datatime

=cut

use Mojo::Base 'DbToRia::DBI::base';
use DbToRia::Exception qw(error);
use Mojo::JSON;
use DBI;

# note: I am unsure, wheter datetime and date should be stored as
# integers or if I should use strings (and even convert internally to a 
# certain format.) :m)
our $map = {
    (map { $_ => 'varchar' } ('text')),
    (map { $_ => 'integer' } ('integer')),
    (map { $_ => 'float' }   ('real')),
    (map { $_ => 'boolean' } ('integer')),  # use 0 as false and 1 as true(?)
    (map { $_ => 'datetime' } ('integer')), # store datetime as seconds since 1970-01-01 00:00:00 UTC (?)
    (map { $_ => 'date' } ('integer')),     # same as datetime (?)
};


sub mapType {
    my $self = shift;
    my $type = shift;
    return $map->{$type} || die error(9844,'Unknown Database Type: "'.$type.'"');
}

=head2 getAllTables()

Returns a list of tables available.

=cut

sub getAllTables {
    my $self = shift;   

    return ["about to find out how this has to work.."];
    
}
