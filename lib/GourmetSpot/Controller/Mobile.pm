package GourmetSpot::Controller::Mobile;

use strict;
use warnings;
use parent 'Catalyst::Controller::Mobile::JP';
use Geo::Coordinates::Converter;
use Geo::Google::StaticMaps::Navigation;

sub auto :Private {
    my ( $self, $c ) = @_;

    if ($c->req->mobile_agent->is_non_mobile) {
        $c->res->redirect($c->uri_for('/'));
        return 0;
    }
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
    if ( my $address = $c->req->param('q') ) {
        my $geo = $c->model('Geo')->get({q => $address})->parse_response;
        if ($geo->{Response}{Status}{code} == 200) {
            warn $geo->{Response}{Status}{code};
            my @coordinates = split(',', $geo->{Response}{Placemark}{Point}{coordinates});
            $point = Geo::Coordinates::Converter->new(
                lat => $coordinates[1],
                lng => $coordinates[0],
                datum => 'wgs84',
            );
            warn $point;
            $c->stash(
                address => $address,
            );
        }
    } else {
        if ( $c->req->mobile_agent->is_docomo ) {
            if ($c->req->param('LAT') && $c->req->param('LON')) {
                $point = Geo::Coordinates::Converter->new(
                    lat => $c->req->param('LAT'),
                    lng => $c->req->param('LON'),
                    datum => $c->req->param('GEO'),
                );
            }
        } elsif ( $c->req->mobile_agent->is_ezweb ) {
            if ($c->req->param('lat') && $c->req->param('lon')) {
                $point = Geo::Coordinates::Converter->new(
                    lat => $c->req->param('lat'),
                    lng => $c->req->param('lon'),
                    datum => $c->req->param('datum'),
                );
            }
        } elsif ( $c->req->mobile_agent->is_softbank ) {
            if ($c->req->param('pos') =~ m{N([\d\.]+)E([\d\.]+)}) {
                $point = Geo::Coordinates::Converter->new(
                    lat => $1,
                    lng => $2,
                    datum => $c->req->param('geo'),
                );
            }
        }
        if ( $point ) {
            $point->convert(wgs84 => 'degree');

            my $geo = $c->model('Geo')->get({ll => join(',', $point->lat, $point->lng)})->parse_response;
            if ($geo->{Response}{Status}{code} == 200) {
                $c->stash(
                    address => $geo->{Response}{Placemark}{p1}{address}
                );
            }
        }
    }

    if ($point) {

        my $distance = sprintf("((acos(sin((%s*pi()/180)) * sin((latitude * pi()/180)) + cos((%s*pi()/180)) * cos((latitude * pi()/180)) * cos(((%s - longitude )*pi()/180)))) *180*60*1853/pi())",
            $point->lat,
            $point->lat,
            $point->lng
        );
        my $rs = $c->model('DBIC::Restrant')->search(
            {},
            {
                '+select' => [
                    "$distance as distance",
                ],
                order_by => 'distance',
                rows => 5,
                page => 1,
            }
        );
        $c->stash(
            list => [ $rs->all ],
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
