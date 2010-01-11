package GourmetSpot::Controller::Mobile;

use strict;
use warnings;
use parent 'Catalyst::Controller::Mobile::JP';
use Geo::Google::StaticMaps::Navigation;
use URI::Escape;
use HTML::MobileJp;

sub auto :Private {
    my ( $self, $c ) = @_;

    if ($c->req->mobile_agent->is_non_mobile) {
        $c->res->redirect($c->uri_for('/'));
        return 0;
    }
    if ($c->req->mobile_agent->is_docomo && ! $c->req->param('guid')) {
        # XXX mmmm.... no need to append %{$c->req->params} but...
        $c->res->redirect($c->req->uri_with({%{$c->req->params}, guid => 'ON'}));
        return 0;
    }
    $c->forward('setup_ugo2');
    return 1;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

sub restrant :Path('restrant') :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $item = $c->model('DBIC::Restrant')->find($id)
        or return $c->res->redirect($c->uri_for());
    $c->forward('setup_map', [ $item ]);
    $c->stash(
        item => $item,
    );
}

sub map :Path('map') :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $item = $c->model('DBIC::Restrant')->find($id)
        or return $c->res->redirect($c->uri_for());
    $c->forward('setup_map', [ $item ]);
    $c->stash(
        item => $item,
    );
}

sub setup_ugo2 :Private {
    my ( $self, $c ) = @_;
    $self->{ugo2} or return;
    my $ugo2 = URI->new('http://b07.ugo2.jp/');
    my $uri = $c->req->uri;
    $ugo2->query_form(
        u => $self->{ugo2}->{u},
        h => $self->{ugo2}->{h},
        guid => 'ON',
        ut => $self->{ugo2}->{ut},
        qM => uri_escape(
            join('|',
                $c->req->referer,
                'Az',
                $uri->port,
                $uri->host,
                $uri->path_query,
                'P'
            )
        ),
        ch => 'UTF-8',
        sb => 'gourmetspot.jp',
    );

    $c->stash(
        ugo2 => $ugo2,
    );
}

sub setup_map :Private {
    my ( $self, $c, $item ) = @_;
    my $map = Geo::Google::StaticMaps::Navigation->new(
        key => $c->config->{googlemaps}->{$c->req->uri->host},
        center => [
            $c->req->param('lat') || $item->latitude,
            $c->req->param('lng') || $item->longitude,
        ],
        size => [
            $c->req->mobile_agent->display->width || 100,
            $c->req->mobile_agent->display->width || 100,
        ],
        zoom => $c->req->param('zoom') || 17,
        markers => [ 
            {
                size => 'small',
                point => [$item->latitude,$item->longitude,],
            }
        ],
    );
    $c->log->_dump($map) if $c->debug;
    $c->stash(
        map  => $map,
    );
}

sub setup_location :Private {
    my ($self, $c, @args) = @_;
    $self->_args_to_params($c, \@args);
    my $point;
    my $mapapi = $c->model('Map');
    my ($address, @points) = $mapapi->get_point($c->req);
    if (scalar @points == 1) {
        $point = $points[0];
        $c->req->param(_lat => $point->lat);
        $c->req->param(_lng => $point->lng);
        $c->stash(
            point => $point,
        );
    } elsif (scalar @points > 1) {
        $c->stash(
            candidates => \@points,
        );
        $c->detach;
    }
}

sub search :Path('search') :Args() {
    my ( $self, $c, @args) = @_;
    $c->forward('setup_location', \@args);
    if (my $point = $c->stash->{point}) {
        my @tag_id = $c->req->param('tag_id');
        my $arg = {
            resultset => $c->model('DBIC::Restrant'),
            coordinates => $point,
            tag_id => $c->req->param('tag_id') ? [ @tag_id ] : undef,
        };
        my $rs = $c->model('Restrant')->search_with_coordinates($arg);
        my @tags_nearby = $c->model('Restrant')->tags_nearby($arg);
        $c->stash(
            list => [ $rs->all ],
            tags => \@tag_id,
            tags_nearby => \@tags_nearby,
            lat => $point->lat,
            lng => $point->lng,
        );
    }
}

sub form :Local :Args() {
    my ($self, $c, @args) = @_;
    $c->forward('setup_location', \@args);

    $c->stash(
        loc_callback => $self->_params_to_args($c, $c->uri_for('search', $c->req->params)),
    );
}

sub end :Private {
    my ( $self, $c ) = @_;

    $c->forward('render');
    $c->fillform;
    $c->forward( $c->view('MobileJpFilter') );
    $self->next::method($c);
}

sub render :ActionClass('RenderView') {}

sub _params_to_args {
    my ($self, $c, $uri) = @_;
    my %params = $uri->query_form;
    my $tag_id = delete $params{tag_id};
    $uri->query(undef);
    my $path = join ('/', 
        $uri->path, 
        map({$_, ($params{$_} || '-') } sort keys %params),
        $tag_id ? (tag_id => ref $tag_id ? @$tag_id : $tag_id) : ()
    );
    $uri->path($path);
    $c->log->debug($uri) if $c->debug;
    return $uri;
}

sub _args_to_params {
    my ($self, $c, $args) = @_;
    while (my $key = shift @$args) {
        if ($key eq 'tag_id') {
            my @value = grep {$_ ne '-'} @$args;
            if (scalar @value) {
                $c->req->param($key => @value);
            }
            last;
        }
        my $value = shift @$args;
        if ($value ne '-') {
            $c->req->param($key => $value);
        }
    }
    $c->log->_dump($c->req->params) if $c->debug;
}

1;
