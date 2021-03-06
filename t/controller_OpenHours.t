use t::Util;
use Test::More tests => 24;
use JSON;

BEGIN { use_ok 'GourmetSpot::Controller::OpenHours' }

my $mech = setup_user_and_login;

my $oh = {
    day_of_week => 'Sun,Sat',
    opens_at => '09:30:00',
    closes_at => '17:00:00',
    holiday => '',
    pre_holiday => '',
};

# create restrant (4 tests)
{
    $mech->get_ok('/restrant/create');
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                name => '株式会社ソフリット',
                tel => '03-3460-4717',
                address => '東京都目黒区駒場4-3-9',
                building => '駒場グリーンハウス201',
                how_to_get_there => '駒場東大前駅下車5分',
                latitude => '35.662191',
                longitude => '139.681317',
                panorama => ' {"latlng": {"lat": 35.662128, "lng": 139.681612}, "pov": {"yaw": 226.85486732456948, "pitch": 14.019279372900145, "zoom": 1}}',
                'openhours[0].day_of_week' => [split(',', $oh->{day_of_week})],
                'openhours[0].opens_at_hour' => (split(':',$oh->{opens_at}))[0],
                'openhours[0].opens_at_minute' => (split(':',$oh->{opens_at}))[1],
                'openhours[0].closes_at_hour' => (split(':',$oh->{closes_at}))[0],
                'openhours[0].closes_at_minute' => (split(':',$oh->{closes_at}))[1],
            }
        }
    );
    $mech->content_like(qr/株式会社ソフリット/);
}
# get_json and delete (20 tests)
{
    $mech->follow_link_ok({text_regex => qr/編集/});
    my ($restrant_id) = $mech->uri->path =~ m{/restrant/(\d+)/update};
    ok $restrant_id;
    $mech->get_ok('/openhours', {restrant_id => $restrant_id});
    ok my $json = from_json($mech->content);
    is ref $json, 'ARRAY';
    is scalar @$json, 1;
    my $oh_id = delete $json->[0]->{id};
    is_deeply $json->[0], {
        %$oh,
        restrant_id => $restrant_id,
    };
    $mech->get_ok("/openhours/$oh_id");
    ok my $json2 = from_json($mech->content);
    is ref $json2, 'HASH';
    is_deeply $json2, {
        %$oh,
        restrant_id => $restrant_id,
        id => $oh_id,
    };
    $mech->get_ok("/openhours/$oh_id/delete");
    is( scalar @{$mech->forms}, 0 );
    $mech->get_ok("/openhours/$oh_id");

    $mech->post_ok("/openhours/$oh_id/delete");
    is( scalar @{$mech->forms}, 0 );
    $mech->get_ok("/openhours/$oh_id");

    $mech->get_ok("/restrant/$restrant_id/update");
    $mech->form_number(1);
    my $token = $mech->value('_token');
    $mech->post_ok("/openhours/$oh_id/delete", {_token => $token});
    $mech->get("/openhours/$oh_id");
    is( $mech->status, 404 );
}
