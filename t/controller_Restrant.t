use t::Util;
use Test::More tests => 58;
use JSON;

BEGIN { use_ok 'GourmetSpot::Controller::Restrant' }

sub oh2form {
    my $ohs = shift;
    my $form = {};
    my $c = -1;
    for ( @{$ohs} ) {
        $c++;
        scalar %$_ or next;
        $form = {
            %$form,
            'OpenHours['.$c.'].id' => $_->{id} || undef,
            'OpenHours['.$c.'].holiday' => $_->{holiday} || undef,
            'OpenHours['.$c.'].pre_holiday' => $_->{pre_holiday} || undef,
            'OpenHours['.$c.'].day_of_week' => [split(',', $_->{day_of_week} || '')],
            'OpenHours['.$c.'].opens_at_hour' => $_->{opens_at} ? (split(':',$_->{opens_at}))[0] : '',
            'OpenHours['.$c.'].opens_at_minute' => $_->{opens_at} ? (split(':',$_->{opens_at}))[1] : '',
            'OpenHours['.$c.'].closes_at_hour' => $_->{closes_at} ? (split(':',$_->{closes_at}))[0] : '',
            'OpenHours['.$c.'].closes_at_minute' => $_->{closes_at} ? (split(':',$_->{closes_at}))[1] : '',
        };
    }
    return $form;
}

my $oh = {
    day_of_week => 'Sun,Sat',
    opens_at => '09:30:00',
    closes_at => '17:00:00',
    holiday => '',
    pre_holiday => '',
};
my $oh2 = {
    day_of_week => '',
    opens_at => '12:30:00',
    closes_at => '16:00:00',
    holiday => 1,
    pre_holiday => 1,
};

my $r = {
    name => '株式会社ソフリット',
    tel => '03-3460-4717',
    address => '東京都目黒区駒場4-3-9',
    building => '駒場グリーンハウス201',
    how_to_get_there => '駒場東大前駅下車5分',
    latitude => '35.662191',
    longitude => '139.681317',
    panorama => ' {"latlng": {"lat": 35.662128, "lng": 139.681612}, "pov": {"yaw": 226.85486732456948, "pitch": 14.019279372900145, "zoom": 1}}',
};

my $mech = setup_user_and_login;

# get list (2 tests)
{
    $mech->get_ok('/member/restrant');
    $mech->follow_link_ok({text => '新しいお店を登録する'});
}

# post without token (2 tests)
{
    $mech->post_ok('/member/restrant/create', {
            %$r,
            %{oh2form([ $oh ])},
        }
    );
    ok( $mech->form_number(1) );
}

# post with invalid token (2 tests)
{
    $mech->post_ok('/member/restrant/create', {
            _token => 'hogehoge',
            %$r,
            %{oh2form([ $oh ])},
        }
    );
    ok( $mech->form_number(1) );
}


# form error (5 tests)
{
    $mech->get_ok('/member/restrant/create');
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                %$r,
                %{oh2form([ $oh ])},
                'name' => '',
                'latitude' => '',
                'longitude' => '',
            }
        }
    );
    ok( $mech->form_number(1) );
    $mech->content_like(qr/お店の名前を入力してください/);
    $mech->content_like(qr/場所を地図で指定してください/);
}

# normal post (9 tests)
{
    $mech->get_ok('/member/restrant/create');
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                %$r,
                %{oh2form([ $oh ])},
            }
        }
    );
    my @got = schema->resultset('OpenHours')->all;
    is scalar @got, 1;
    my %cols = $got[0]->get_columns;
    ok delete $cols{restrant_id};
    ok delete $cols{id};
    is_deeply \%cols, $oh;
    $mech->title_like(qr/お店情報/);
    $mech->content_like(qr/$r->{name}/);
    $mech->follow_link_ok({text => '編集'});
}

# error update (7 tests)
{
    $mech->get_ok('/member/restrant');
    $mech->title_like(qr/お店検索/);
    my $link = $mech->find_link(url_regex => qr{/member/restrant/\d+});
    my ($id) = $link->URI->path =~ m{/member/restrant/(\d+)$};
    $mech->get('/member/open_hours/', {restrant_id => $id});
    my $json = from_json($mech->content);

    $mech->get_ok($link->url);
    $mech->follow_link_ok({text => '編集'});
    $r->{name} = '',
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                %$r,
                %{oh2form($json)},
            }
        }
    );
    ok( $mech->form_number(1) );
    $mech->content_like(qr/お店の名前を入力してください/);
}

# normal update (5 tests)
{
    $mech->get_ok('/member/restrant');
    $mech->title_like(qr/お店検索/);
    my $link = $mech->find_link(url_regex => qr{/member/restrant/\d+});
    my ($id) = $link->URI->path =~ m{/member/restrant/(\d+)$};
    $mech->get('/member/open_hours/', {restrant_id => $id});
    my $json = from_json($mech->content);

    $mech->get_ok($link->url);
    $mech->follow_link_ok({text => '編集'});
    $r->{name} = '店名書き換え';
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                %$r,
                %{oh2form($json)},
            }
        }
    );
}

# normal update (5 tests)
{
    $mech->get_ok('/member/restrant');
    $mech->title_like(qr/お店検索/);
    my $link = $mech->find_link(url_regex => qr{/member/restrant/\d+});
    my ($id) = $link->URI->path =~ m{/member/restrant/(\d+)$};
    $mech->get('/member/open_hours/', {restrant_id => $id});
    my $json = from_json($mech->content);
    for (qw(day_of_week holiday pre_holiday)) {
        delete $json->[0]->{$_};
    }
    push @$json, ({}, $oh2,{
            day_of_week => '',
            opens_at => '12:30:00',
            closes_at => '16:00:00',
            holiday => '',
            pre_holiday => '',
        },
        {
            day_of_week => '',
            opens_at => '12:30:00',
            closes_at => '16:00:00',
            holiday => '',
            pre_holiday => 1,
        },
        {
            day_of_week => ['Sat'],
            opens_at => '12:30:00',
        },
        {},
        {
            day_of_week => ['Mon'],
            closes_at => '12:30:00',
        }
    );
    $mech->get_ok($link->url);
    $mech->follow_link_ok({text => '編集'});
    $r->{name} = '店名書き換え';
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                %$r,
                %{oh2form($json)},
            }
        }
    );
}

{
    $mech->title_like(qr/お店情報/);
    $mech->content_like(qr/$r->{name}/);
    $mech->follow_link_ok({text => '編集'});
    $r->{name} = '店名書き換え（さらに）';
    $mech->post_with_token_ok(
        {
            form_number => 1,
            fields => {
                %$r,
                %{oh2form([ $oh, {}, $oh2 ])},
            }
        }
    );
    $mech->content_like(qr/$r->{name}/);
}

# update without token (5 tests)
{
    $mech->get_ok('/member/restrant');
    my $link = $mech->find_link(url_regex => qr{/member/restrant/\d+});
    my ($restrant_id) = $link->URI->path =~ m{/member/restrant/(\d+)$};
    $mech->post_ok("/member/restrant/$restrant_id/update",
        {
            %$r,
            %{oh2form([ $oh2 ])},
        }
    );
    $mech->title_like(qr/お店を登録/);
    ok( $mech->form_number(1) );
    is( $mech->value('name'), $r->{name} );
}

# delete without token (5 tests)
{
    $mech->get_ok('/member/restrant');
    my $link = $mech->find_link(url_regex => qr{/member/restrant/\d+});
    my ($restrant_id) = $link->URI->path =~ m{/member/restrant/(\d+)$};
    $mech->post_ok("/member/restrant/$restrant_id/delete");
    $mech->title_like(qr/お店を削除/);
    ok( $mech->form_number(1) );
    $mech->get_ok("/member/restrant/$restrant_id");
}

# delete (5 tests)
{
    $mech->get_ok('/member/restrant');
    my $link = $mech->find_link(url_regex => qr{/member/restrant/\d+});
    my ($restrant_id) = $link->URI->path =~ m{/member/restrant/(\d+)$};
    $mech->follow_link(url_regex => qr{/member/restrant/\d+});
    $mech->follow_link_ok({text => '削除'});
    $mech->submit_form_ok(
        {
            form_number => 1,
        }
    );
    is( $mech->uri->path, '/member/restrant' );
    $mech->get("/member/restrant/$restrant_id");
    is( $mech->status, '404' );
}
