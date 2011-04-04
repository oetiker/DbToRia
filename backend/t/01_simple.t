#!/usr/bin/perl

# note for self: with current config.cfg a PostGres db is used.
# this requires DBD:Pg to be installed an the respective DB being in place.
# otherwise some tests will fail.

use strict;

use FindBin;
use lib $FindBin::Bin.'/../lib';

use lib $FindBin::Bin.'/../../thirdparty/lib/perl5';
use Test::More tests => 43;
use Test::Mojo;

use_ok 'MojoX::Dispatcher::Qooxdoo::Jsonrpc';
use_ok 'DbToRia::MojoApp';

my $t = Test::Mojo->new(app => DbToRia::MojoApp->new());

# Gain Login: works with proper db in place only (see README)

# Request ok, using existent service and method (login).
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"login","params":[{"username":"dbtoria_test_user", "password": "abc"}]}')
    ->json_content_is({id=>1,result=>1},'login successful')
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);
  
# From here we are working with the login obtained in the test above.
 
# Request tables.
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getTables"}')
    ->json_content_is(
        {
            id => 1,
            result => {
                chocolate => {
                    name        => 'chocolate',
                    type        => 'TABLE'
                },
                favourite => {
                    name        => 'favourite',
                    type        => 'TABLE'
                }
            }
        },
        'tables in db'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);
  
# Fetch structure of table chocolate
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getTableStructure","params":["chocolate"]}')
  ->json_content_is(
        {
            id => 1,
            result => {
                typeMap => {    
                    chocolate_id        => 'integer',
                    chocolate_flavour   => 'character varying'
                },
                columns => [
                    {
                        primary             => 1,
                        name                => 'chocolate_id',
                        size                => 4,
                        required            => 1,
                        references          => undef,
                        id                  => 'chocolate_id',
                        type                => 'integer',
                        pos                 => 1
                    },
                    {
                        primary             => undef,
                        name                => 'chocolate_flavour',
                        size                => 50,
                        required            => '',
                        references          => undef,
                        id                  => 'chocolate_flavour',
                        type                => 'varchar',
                        pos                 => 2
                    }
                ],
                
                meta => {
                    primary => [
                        "chocolate_id"
                    ]
                }
            }
        },
        'table sctructure'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);

#~ # Fetch rowCount
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRowCount","params":["chocolate"]}')
    ->json_content_is(
        {
            id          => 1,
            result      => 4
        },
        'row count'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);
  
# Fetch an existing record
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "3"]}')
    ->json_content_is(
        {
            id      => 1,
            result  => {
                chocolate_flavour   => 'Milk chocolate',
                chocolate_id        => '3'
            }
        },
        'fetch existing record'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);  
  
# Fetch an inexistent record
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "6"]}')
    ->json_content_is(
        {
            id         => 1,
            result     => {}
        },
        'try to fetch inexistent record'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);  
  
# SQL-error (wrong parameter type)
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "notanumber"]}')
    ->content_like(
        qr/error.*"code":70221502/,
        'SQL-error (wrong parameter type)'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);  
  
# Get list view
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getListView","params":["chocolate"]}')
    ->json_content_is(
        {
            id          => 1,
            result      => {
                tableId     => 'chocolate',
                columns     => [
                    {
                        name    => 'chocolate_id',
                        type    => 'integer',
                        id      => 'chocolate_id',
                        size    => 4
                    },
                    {
                        name    => 'chocolate_flavour',
                        type    => 'varchar',
                        id      => 'chocolate_flavour',
                        size    => 50
                    }
                ]
            }
        },
        'get list view'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200); 
    
# getEditView(table)
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getEditView","params":["chocolate"]}')
    ->json_content_is(
        {
            "id"    => 1,
            "result"    =>[
                {
                    name      => 'chocolate_id',
                    type      => 'TextField',
                    label     => 'chocolate_id'
                },
                {
                    name      => 'chocolate_flavour',
                    type      => 'TextField',
                    label     => 'chocolate_flavour'
                }
            ]
        },
        'getEditView'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);
    
# getForm (table,recordId): forget recordID an get all null
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getForm","params":["chocolate"]}')
    ->json_content_is(
        {
            "id"    => 1,
            "result"    =>[
                {
                    name      => 'chocolate_id',
                    initial   => undef,
                    type      => 'TextField',
                    label     => 'chocolate_id'
                },
                {
                    name      => 'chocolate_flavour',
                    initial   => undef,
                    type      => 'TextField',
                    label     => 'chocolate_flavour'
                }
            ]
        },
        'getForm ("forget" recordId)'
    ) 
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);

# ..and correct recordId
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getForm","params":["chocolate", "2"]}')
    ->json_content_is(
        {
            "id"    => 1,
            "result"    =>[
                {
                    name      => 'chocolate_id',
                    initial   => 2,
                    type      => 'TextField',
                    label     => 'chocolate_id'
                },
                {
                    name      => 'chocolate_flavour',
                    initial   => 'Semisweet chocolate',
                    type      => 'TextField',
                    label     => 'chocolate_flavour'
                }
            ]
        },
        'getForm'
    ) 
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);
    
# insertTableData where we have no insert rights
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"insertTableData","params":["chocolate",{"chocolate_flavour":"schüümli"}]}')

    
    ->content_like(
        qr/error.*"code":70042501/,
        'insertTableData without appropriate rights (fail)'
    )
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);
    
# login as admin
$t  ->post_ok('/jsonrpc','{"id":2,"service":"DbToRia","method":"login","params":[{"username":"dbtoria_test_admin", "password": "xyz"}]}')
    ->json_content_is({id=>2,result=>1},'login successful', 'login as dbtoria_test_admin')
    ->content_type_is('application/json; charset=utf-8')
    ->status_is(200);

    
# insertTableData with admin rights
$t  ->post_ok('/jsonrpc','{"id":2,"service":"DbToRia","method":"insertTableData","params":["favourite",{"favourite_name":":m)","favourite_chocolate":1}]}')
    ->content_is('not this, but should not be an error..');
    
# delete record again
#todo
    
# updateTableData
$t  ->post_ok('/jsonrpc','{"id":2,"service":"DbToRia","method":"updateTableData","params":["chocolate","1",{"chocolate_flavour":"very Dark chocolate"}]}')
    ->json_content_is({"id"=>2,"result"=>1}, 'update dark chocolate to very dark');
    
# check if chocolate has become *very* dark, which is always desirable
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "1"]}')
    ->json_content_is(
        {
            id      => 1,
            result  => {
                chocolate_flavour   => 'very Dark chocolate',
                chocolate_id        => '1'
            }
        },
        'check if chocolate has become very dark'
    );
# set chocolate back to dark
$t  ->post_ok('/jsonrpc','{"id":2,"service":"DbToRia","method":"updateTableData","params":["chocolate","1",{"chocolate_flavour":"Dark chocolate"}]}')
    ->json_content_is({"id"=>2,"result"=>1}, 'update dark chocolate to very dark');
    
# check if chocolate has become dark again
$t  ->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "1"]}')
    ->json_content_is(
        {
            id      => 1,
            result  => {
                chocolate_flavour   => 'Dark chocolate',
                chocolate_id        => '1'
            }
        },
        'check if chocolate has become very dark'
    )
    
