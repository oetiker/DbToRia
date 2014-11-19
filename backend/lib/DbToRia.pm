package DbToRia;
use strict;
use warnings;

use DbToRia::RpcService;
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
    my $gcfg = $self->cfg->{General};
    $self->secrets([$gcfg->{mojo_secret}]);
    if ($self->app->mode ne 'development' and $gcfg->{log_file}){
        $self->log->path($gcfg->{log_file});
    }
    if ($gcfg->{log_level}){
        $self->log->level($gcfg->{log_level});
    }
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
            DbToRia  => new DbToRia::RpcService(
                cfg => $self->cfg,
                log => $self->app->log,
           )
        }
    });
}

1;
