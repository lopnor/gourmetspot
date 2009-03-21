package GourmetSpot::Controller::Mobile;

use strict;
use warnings;
use parent 'Catalyst::Controller::Mobile::JP';
use Geo::Coordinates::Converter;
use Geo::Coordinates::Converter::iArea;

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

sub search :Path('search') :Args(0) {
    my ( $self, $c ) = @_;

    my $point;
    if ( $c->req->mobile_agent->is_docomo ) {
        if ( my $iarea = $c->req->param('AREACODE') ) {
            $point = Geo::Coordinates::Converter::iArea->get_center($iarea);
        }
    } elsif ( $c->req->mobile_agent->is_ezweb ) {
        $point = Geo::Coordinates::Converter->new(
            lat => $c->req->param('lat'),
            lng => $c->req->param('lon'),
            datum => $c->req->param('datum'),
        );
    } elsif ( $c->req->mobile_agent->is_softbank ) {
        if ($c->req->param('pos') =~ m{N([\d\.]+)E([\d\.]+)}) {
            $point = Geo::Coordinates::Converter->new(
                lat => $1,
                lng => $2,
                datum => $c->req->param('geo'),
            );
        }
    }

    if ($point) {
        $point->convert(wgs84 => 'degree');

        my $distance = sprintf("((acos(sin((%s*pi()/180)) * sin((latitude * pi()/180)) + cos((%s*pi()/180)) * cos((latitude * pi()/180)) * cos(((%s - latitude )*pi()/180)))) *180*60*1853/pi())",
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
