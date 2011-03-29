# note for self: with current config.cfg a PostGres db is used.
# this requires DBD:Pg to be installed an the respective DB being in place.
# otherwise some tests will fail.



use FindBin;
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/../../thirdparty/lib/perl5';

use Test::More tests => 43;
use Test::Mojo;

use_ok 'MojoX::Dispatcher::Qooxdoo::Jsonrpc';
use_ok 'DbToRia::MojoApp';

my $t = Test::Mojo->new(app => DbToRia::MojoApp->new());

# Send an invalid jsonrpc-request. Parameter 2 is not a valid json object string.
$t->post_ok('/jsonrpc','x','non-jsonrpc request sent')
  ->content_like(qr/This is not a JsonRPC request/,'bad request identified')
  ->status_is(500);
  
# Send an incomplete request. json object string must contain name of service. Omitted.
$t->post_ok('/jsonrpc','{"id":1,"method":"test"}','request without service')
  ->content_like(qr/Missing service property/,'missing service found');
  
# Send an incomplete request. json object string "method" properti missing.
$t->post_ok('/jsonrpc','{"id":1,"service":"sdf"}','request without method')
  ->content_like(qr/Missing method property/, 'missing method found');
  
# Request ok, but requesting inexistent servce "notthere".
$t->post_ok('/jsonrpc','{"id":1,"service":"notthere","method":"test"}','requesting unknown service')
  ->json_content_is({error=>{origin=>1,code=>2,message=>"service notthere not available"},id=>1},'json error for invalid service')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);
  
# Request ok, but requesting inextstent method "notthere".
$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"notthere"}','requesting invalid method')
  ->json_content_is({error=>{origin=>1,code=>2,message=>"service rpc not available"},id=>1},'json error for invalid method');


# Gain Login: works with proper db in place only (see README)

# Request ok, using existent service and method (login).
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"login","params":[{"username":"dbtoria_test_user", "password": "abc"}]}')
  ->content_is('{"id":1,"result":1}','proper response')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);
  
# From here we are working with the login obtained in the test above.
 
# Request tables.
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getTables"}')
  ->content_is('{"id":1,"result":[{"name":"chocolate","type":"TABLE","id":"chocolate"},{"name":"favourite","type":"TABLE","id":"favourite"}]}','proper response')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);
  
# Fetch structure of table chocolate
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getTableStructure","params":["chocolate"]}')
  ->content_is('{"id":1,"result":{"typeMap":{"chocolate_flavour":"character varying","chocolate_id":"integer"},"columns":[{"primary":1,"name":"chocolate_id","size":4,"required":"1","references":null,"id":"chocolate_id","type":"integer","pos":1},{"primary":null,"name":"chocolate_flavour","size":50,"required":"","references":null,"id":"chocolate_flavour","type":"varchar","pos":2}],"meta":{"primary":["chocolate_id"]}}}')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);

# Fetch rowCount
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRowCount","params":["chocolate"]}')
  ->content_is('{"id":1,"result":"4"}')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);
  
# Fetch an existing record
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "3"]}')
  ->content_is('{"id":1,"result":{"chocolate_flavour":"Milk chocolate","chocolate_id":"3"}}')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);  
  
# Fetch an inexistent record
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "6"]}')
  ->content_is('{"id":1,"result":{}}')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200);  
  
# SQL-error! displays SQL error on console, problem: partly in localized language..
#~ $t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getRecord","params":["chocolate", "notanumber"]}')
  #~ ->content_is('{"id":1,"result":{}}')
  #~ ->content_type_is('application/json; charset=utf-8')
  #~ ->status_is(200);  
  
# Get list view
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getListView","params":["chocolate"]}')
  ->content_is('{"id":1,"result":[{"name":"chocolate_id","type":"integer","id":"chocolate_id","size":4},{"name":"chocolate_flavour","type":"varchar","id":"chocolate_flavour","size":50}]}')
  ->content_type_is('application/json; charset=utf-8')
  ->status_is(200); 
