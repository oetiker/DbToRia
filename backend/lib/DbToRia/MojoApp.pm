package DbToRia::MojoApp;
use strict;
use warnings;

use DbToRia::JsonRpcService;
use DbToRia::Config;
use DbToRia::Session;

use Mojo::Base 'Mojolicious';

has 'cfg' => sub {
    my $self = shift;
    my $conf = DbToRia::Config->new( 
        file=> $ENV{DBTORIA_CONF} || $self->home->rel_file('etc/dbtoria.cfg')
    );
    return $conf->parse_config();
};

sub startup {
    my $self = shift;

    $self->secret($self->cfg->{General}{secret});

    $self->app->hook(before_dispatch => sub {
        my $self = shift;
        $self->stash->{'mojo.session'} ||= {};
        my $session = DbToRia::Session->new(
            id=>$self->stash('mojo.session')->{id}
        );
        $self->stash('mojo.session')->{id} = $session->id;
        $self->stash->{'dbtoria.session'} = $session;
    });

    $self->plugin('qooxdoo_jsonrpc',{
        services => {
            DbToRia  => new DbToRia::JsonRpcService(
                cfg => $self->cfg,
                log => $self->app->log,
           )
        }
    });
}

1;
