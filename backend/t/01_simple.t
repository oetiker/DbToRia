# note for self: with current config.cfg a PostGres db is used.
# this requires DBD:Pg to be installed an the respective DB being in place.
# otherwise some tests will fail.


use Test::More tests => 23;
use Test::Mojo;

use FindBin;
use lib $FindBin::Bin.'/../lib';

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
  
# Request ok, but requesting inexistent servce "notthere"
$t->post_ok('/jsonrpc','{"id":1,"service":"notthere","method":"test"}','requesting unknown service')
  ->json_content_is({error=>{origin=>1,code=>2,message=>"service notthere not available"},id=>1},'json error for invalid service')
  ->content_type_is('application/json')
  ->status_is(200);
  
# Request ok, but requesting inextstent method "notthere"
$t->post_ok('/jsonrpc','{"id":1,"service":"rpc","method":"notthere"}','requesting invalid method')
  ->json_content_is({error=>{origin=>1,code=>2,message=>"service rpc not available"},id=>1},'json error for invalid method');


# Gain Login: works with proper db in place only

# Request ok, using existent service and method (login)
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"login","params":[{"username":"test", "password": "xyz"}]}')
  ->content_is('{"id":1,"result":1}','proper response')
  ->content_type_is('application/json')
  ->status_is(200);
  
# From here we are working with the login obtained in the test above  
 
# Request tables
$t->post_ok('/jsonrpc','{"id":1,"service":"DbToRia","method":"getTables"}')
  ->content_is('{"id":1,"result":[{"name":"testdb","type":"TABLE","id":"testdb"}]}','proper response')
  ->content_type_is('application/json')
  ->status_is(200);
  

