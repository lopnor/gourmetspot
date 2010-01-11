use strict;
use warnings;
use Test::More;
use HTTP::Request;
BEGIN {
    use_ok 'GourmetSpot::API::Map';
}

ok my $api = GourmetSpot::API::Map->new;

ok my $req = HTTP::Request->new(
    'GET' => 'http://gourmetspot.jp/mobile/search',
    HTTP::Headers->new(
        'X-JPHONE-GEOCODE' => '353944%1A1394053%1ATOKYO',
    )
);


my $geo = $api->gps_to_coordinates($req);
isa_ok $geo, 'Geo::Coordinates::Converter';

warn $geo->lat;
warn $geo->lng;

done_testing;
