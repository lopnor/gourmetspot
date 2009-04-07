use t::Util;
use Test::More tests => 28;

BEGIN { use_ok 'GourmetSpot::Controller::Review' }

my $mech = setup_user_and_login;
{
    $mech->get('/restrant/create');
    $mech->submit_form(
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
            'OpenHours[0].day_of_week' => 'Mon,Wed,Fri',
            'OpenHours[0].opens_at_hour' => '10',
            'OpenHours[0].opens_at_minute' => '30',
            'OpenHours[0].closes_at_hour' => '17',
            'OpenHours[0].closes_at_minute' => '25',
        },
    );
}
{
    $mech->follow_link_ok({text => 'レビューを書く'});
    $mech->title_like(qr/レビューを書く/);
    $mech->submit_form_ok(
        {
            form_number => 1,
        }
    );
    is( scalar @{$mech->forms}, 1 );
    $mech->content_like(qr/予算を入力してください/);
    $mech->content_like(qr/タグを入力してください/);
    $mech->content_like(qr/ヒトコトを入力してください/);
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                budget => '1000',
                'Tag.value' => '会社 サンプル',
                comment => 'コメントです',
            }
        }
    );
    $mech->content_like(qr/レビュー/);
    $mech->content_like(qr/コメントです/);
    $mech->content_like(qr/1000/);
    $mech->content_like(qr/会社/);
    $mech->content_like(qr/サンプル/);
    $mech->follow_link_ok({text => 'レビューを更新'});
    is( scalar @{$mech->forms}, 1 );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                budget => '2000',
                'Tag.value' => '会社 sample',
                comment => 'comment',
            }
        }
    );
}
{
    $mech->get_ok('/review/create');
    is($mech->uri->path, '/review');
}
{
    $mech->post_ok('/review/create',{restrant_id => 1});
    is( scalar @{$mech->forms}, 1 );
    is($mech->uri->path, '/review/create');
}
{
    $mech->get('/review');
    my $link = $mech->find_link( url_regex => qr{/review/\d+$} );
    ok( $mech->find_link( url => $link->url ) );
    $mech->follow_link_ok({url_regex => qr{/review/\d+}});
    $mech->follow_link_ok({text => 'レビューを削除'});
    $mech->submit_form_ok({form_number => 1});
    is( $mech->uri->path, '/review' );
    ok( ! $mech->find_link( url => $link->url ) );
}



