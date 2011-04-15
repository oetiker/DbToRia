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

our $map = {
    (map { $_ => 'varchar' } ('text')),
    (map { $_ => 'integer' } ('integer')),
    (map { $_ => 'float' }   ('real')),
    (map { $_ => 'boolean' } ('integer')),  # use 0 as false and 1 as true(?)
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

    # just return if tableList already exists
    return $self->{tableList} if $self->{tableList};
    my $dbh	= $self->getDbh();

    # SQLite needs "undef" while '' is o.k. for Pg.
    my $sth = $dbh->table_info(undef,undef,undef, 'TABLE');

    my %tables;
    while ( my $table = $sth->fetchrow_hashref ) {
        next unless $table->{TABLE_TYPE} =~ /TABLE/i; # does SQLite have "views", too?

        $tables{$table->{TABLE_NAME}} = {
            type => $table->{TABLE_TYPE},
            name => $table->{REMARKS} || $table->{TABLE_NAME}
    	};
    }
    $self->{tableList} = \%tables;
    return $self->{tableList};

}
