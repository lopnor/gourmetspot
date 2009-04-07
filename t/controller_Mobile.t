use t::Util;
use Encode;
use Test::More tests => 37;
use Data::Dumper;

BEGIN { use_ok 'GourmetSpot::Controller::Mobile' }

my $restrant = {
    name => '株式会社ソフリット',
    tel => '03-3460-4717',
    address => '東京都目黒区駒場4-3-9',
    building => '駒場グリーンハウス201',
    how_to_get_there => '駒場東大前駅下車5分',
    latitude => '35.662191',
    longitude => '139.681317',
    panorama => ' {"latlng": {"lat": 35.662128, "lng": 139.681612}, "pov": {"yaw": 226.85486732456948, "pitch": 14.019279372900145, "zoom": 1}}',
};

{
    schema->resultset('Restrant')->create($restrant);
}

{
    my $mech = guest;
    for my $agent (
        {'User-Agent' => 'DoCoMo/2.0 N04A(c100;TB;W30H20)'},
        {
            'User-Agent' => 'KDDI-SN3A UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0',
            'X-UP-DEVCAP-SCREENPIXELS' => '229,325',
            'X-UP-DEVCAP-SCREENDEPTH' => '16,RGB565',
        },
        {
            'User-Agent' => 'SoftBank/1.0/911T/TJ002 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1',
            'X-JPHONE-DISPLAY' => '800*480',
            'X-JPHONE-COLOR' => 'C262144',
        },
    ) {
#        diag("User-Agent: ", $agent->{'User-Agent'});
        $mech->add_header($_ => $agent->{$_}) for keys %$agent;
#        $mech->agent($agent);
        $mech->get_ok('/mobile');
        is $mech->uri->path, '/mobile';
        ok $mech->find_link(text => '現在地点から検索');
        $mech->submit_form_ok(
            {
                form_number => 1,
                fields => {
                    q => '渋谷',
                }
            },
        );
        $mech->content_like(qr{渋谷付近のお店情報});
        $mech->follow_link_ok({text => $restrant->{name}});
        $mech->content_like(qr{$restrant->{name}});
        ok $mech->find_link(url => "tel:$restrant->{tel}");
        ok my $image = $mech->find_image(url_regex => qr{^http://maps.google.com/staticmap});
        is $image->width, $image->height;
        $mech->follow_link_ok({text => 'out'});
        $mech->follow_link_ok({text => '→'});
    }
}
