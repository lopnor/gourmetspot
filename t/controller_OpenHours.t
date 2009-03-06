use t::Util;
use Test::More tests => 11;
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
    $mech->get_ok('/member/restrant/create');
    $mech->form_number(1);
    my $token = $mech->value('_token');
    $mech->post_ok('/member/restrant/create',
        { 
            _token => $token,
            name => '株式会社ソフリット',
            tel => '03-3460-4717',
            address => '東京都目黒区駒場4-3-9',
            building => '駒場グリーンハウス201',
            how_to_get_there => '駒場東大前駅下車5分',
            latitude => '35.662191',
            longitude => '139.681317',
            panorama => ' {"latlng": {"lat": 35.662128, "lng": 139.681612}, "pov": {"yaw": 226.85486732456948, "pitch": 14.019279372900145, "zoom": 1}}',
            'OpenHours[0].day_of_week' => [split(',', $oh->{day_of_week})],
            'OpenHours[0].opens_at_hour' => (split(':',$oh->{opens_at}))[0],
            'OpenHours[0].opens_at_minute' => (split(':',$oh->{opens_at}))[1],
            'OpenHours[0].closes_at_hour' => (split(':',$oh->{closes_at}))[0],
            'OpenHours[0].closes_at_minute' => (split(':',$oh->{closes_at}))[1],
        }
    );
    $mech->content_like(qr/株式会社ソフリット/);
}
# get_json and delete (6 tests)
{
    $mech->follow_link_ok({text_regex => qr/編集/});
    my ($restrant_id) = $mech->uri->path =~ m{/member/restrant/(\d+)/update};
    ok $restrant_id;
    $mech->form_number(1);
    my $token = $mech->value('_token');
    $mech->get_ok('/member/open_hours', {restrant_id => $restrant_id});
    ok my $json = from_json($mech->content);
    is scalar @$json, 1;
    my $oh_id = delete $json->[0]->{id};
    is_deeply $json->[0], {
        %$oh,
        restrant_id => $restrant_id,
    };
    $mech->post_ok("/member/open_hours/$oh_id/delete", {_token => $token});
}
