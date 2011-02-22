#!/bin/bash
set -e
cd `dirname "$0"`
install=`cd ..;pwd`/thirdparty
[ -d $install ] || mkdir $install
export PERL=perl
#./build_mongodb.sh $install
curl -L cpanmin.us | perl -  --notest --local-lib $install \
        App::cpanminus \
        Mojolicious \
        MojoX::Dispatcher::Qooxdoo::Jsonrpc \
        Config::Grammar \
        DBI

# build postgresql



if [ -d /usr/pack/postgresql-8.4.3-za ]; then
  export POSTGRES_LIB=/usr/pack/postgresql-8.4.3-za/amd64-linux-ubuntu8.04/lib \
  export POSTGRES_INCLUDE=/usr/pack/postgresql-8.4.3-za/amd64-linux-ubuntu8.04/include
fi

cpanm  --notest --local-lib $install \
        DBD::Pg
