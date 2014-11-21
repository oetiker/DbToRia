#!/usr/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../backend/thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../backend/lib';


use Test::More tests => 4;
use Test::Mojo;

use_ok 'Dbtoria';
use_ok 'Dbtoria::Controller::RpcService';

my $t = Test::Mojo->new('Dbtoria');

$t->post_ok('/jsonrpc','{"id":1,"service":"dbtoria","method":"ping","params":["hello"]}')
  ->json_is('',{id=>1,result=>'got hello'},'post request');

exit 0;
