package DbToRia::MojoApp;
use strict;
use warnings;

use DbToRia::JsonRpcService;

use base 'Mojolicious';

__PACKAGE__->attr(cfg => sub {
    my $self = shift;
    my $conf = remOcular::Config->new( 
        file=> $ENV{DBTORIA_CONF} || $self->home->rel_file('etc/dbtoria.cfg')
    );
    return $conf->parse_config();
});

sub startup {
    my $self = shift;

    my $r = $self->routes;

    $self->log->path($self->cfg->{General}{log_file})
        if $self->cfg->{General}{log_file};

    $self->secret($self->cfg->{General}{secret});

    $self->app->hook(before_dispatch => sub {
        my $self = shift;
        $self->stash->{'mojo.session'} ||= {};
        my $session = DbToRia::Session->new(
            id=>$self->stash('mojo.session')->{id}
        );
        $self->stash('mojo.session')->{id} = $session->id;
        $self->stash('dbtoria.session',$session);
    });

    my $services = {
        DbToRia => new DbToRia::JsonRpcService(
             cfg       => $self->cfg
        ),
    };
            
    $SIG{__WARN__} = sub {
        local $SIG{__WARN__};
        $self->log->info(shift);
    };

    if ($ENV{RUN_QX_SOURCE}){
        $r->route('/source/jsonrpc')->to(
            class       => 'Jsonrpc',
            method      => 'dispatch',
            namespace   => 'MojoX::Dispatcher::Qooxdoo',        
            # our own properties
            services    => $services,        
            debug       => 1,        
        );
    
        $self->static->root($self->home->rel_dir('../frontend'));
        $r->get('/' => sub { shift->redirect_to('/source/') });
        $r->get('/source/' => sub { shift->render_static('/source/index.html') });

        my $qx_static = Mojolicious::Static->new();

        $r->route('(*qx_root)/framework/source/(*more)')->to(
            cb => sub {
                my $self = shift;
                my $qx_root = $self->stash('qx_root');
                $qx_static->root('/'.$qx_root);
                $qx_static->prefix('/'.$qx_root);
                return $qx_static->dispatch($self);
            }    
        );
    } else {
        $r->route('/jsonrpc')->to(
            class       => 'Jsonrpc',
            method      => 'dispatch',
            namespace   => 'MojoX::Dispatcher::Qooxdoo',        
            # our own properties
            services    => $services,        
            debug       => 0,        
        );
        $r->get( '/' => sub { shift->render_static('index.html') });
    }
}

1;
