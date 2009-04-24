package GourmetSpot::Controller::Mobile;

use strict;
use warnings;
use parent 'Catalyst::Controller::Mobile::JP';
use Geo::Coordinates::Converter;
use Geo::Google::StaticMaps::Navigation;
use URI::Escape;

sub auto :Private {
    my ( $self, $c ) = @_;

    if ($c->req->mobile_agent->is_non_mobile) {
        $c->res->redirect($c->uri_for('/'));
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

    my $item = $c->model('DBIC::Restrant')->find($id);
    $c->forward('setup_map', [ $item ]);
    $c->stash(
        item => $item,
    );
}

sub map :Path('map') :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $item = $c->model('DBIC::Restrant')->find($id);
    $c->forward('setup_map', [ $item ]);
    $c->stash(
        item => $item,
    );
}

sub setup_ugo2 :Private {
    my ( $self, $c ) = @_;
    my $ugo2 = URI->new('http://b07.ugo2.jp');
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
        zoom_ratio => 2,
        key => $c->config->{googlemaps}->{$c->req->uri->host},
        center => Geo::Coordinates::Converter->new(
            lat => $c->req->param('lat') || $item->latitude,
            lng => $c->req->param('lng') || $item->longitude,
        ),
        width => $c->req->mobile_agent->display->width || 100,
        height => $c->req->mobile_agent->display->width || 100,
        span => $c->req->param('span') || 0.002,
        markers => [ 
            Geo::Coordinates::Converter->new(
                lat => $item->latitude,
                lng => $item->longitude,
            )
        ],
    );
    $c->stash(
        map  => $map,
    );
}

sub search :Path('search') :Args(0) {
    my ( $self, $c ) = @_;
    my $point;
    my $mapapi = $c->model('Map');
    if ( my $address = $c->req->param('q') ) {
        my @points = $mapapi->geocode($address);
        if (scalar @points == 1) {
            $point = $points[0];
        } else {
            $c->stash(
                candidates => \@points,
            );
        }
        $c->stash(
            address => $address,
        );
    } else {
        $point = $mapapi->gps_to_coordinates($c->req);
        if ( $point ) {
            my $address = $mapapi->reverse_geocode($point);
            $c->stash(
                address => $address,
            );
        }
    }
    if ($point) {
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

sub end :Private {
    my ( $self, $c ) = @_;

    $c->forward('render');
    $c->forward( $c->view('MobileJpFilter') );
    $self->next::method($c);
}

sub render :ActionClass('RenderView') {}

1;
