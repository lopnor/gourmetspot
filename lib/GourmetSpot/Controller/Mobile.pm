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

sub search :Path('search') :Args() {
    my ( $self, $c, @args) = @_;
    while (my $key = shift @args) {
        if ($key eq 'tag_id') {
            $c->req->param($key => @args);
            last;
        }
        my $value = shift @args;
        $c->req->param($key => $value);
    }
    $c->log->_dump($c->req->params);
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
    } elsif ( my $gps_mode = $c->req->param('gps_mode') ) {
        my $gps_endpoint = {
            'DoCoMo' => 'http://w1m.docomo.ne.jp/cp/iarea?ecode=OPENAREACODE&msn=OPENAREAKEY&posinfo=1&nl=',
            'EZweb' => 'device:location?url=',
            'Vodafone' => 'location:auto?url=',
        };
        my $endpoint = $gps_endpoint->{$c->req->mobile_agent->carrier_longname};
        if ($endpoint) {
            my @tag_id = $c->req->param('tag_id');
            $c->log->_dump( \@tag_id );
            my $url = $c->uri_for('search',
                gps_mode => 0,
                now_available => $c->req->param('now_available') || 0,
                q => $c->req->param('q'),
                tag_id => @tag_id,
            );
            $c->log->debug($url);
            $c->res->redirect( $endpoint . uri_escape($url) );
            $c->detach;
        }
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
