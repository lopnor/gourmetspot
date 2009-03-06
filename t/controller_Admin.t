use t::Util;
use Test::More tests => 30;

#use_ok test (4 tests)
BEGIN { use_ok 'Test::WWW::Mechanize::Catalyst', 'GourmetSpot' }
BEGIN { use_ok 'GourmetSpot::Controller::Admin' }
BEGIN { use_ok 'GourmetSpot::Schema' }
BEGIN { use_ok 'GourmetSpot::Util::ConfigLoader' }

my $admin = +{
    mail => 'admin+'.time.'@soffritto.org',
    password => 'admin_for_test',
    nickname => 'テスト管理者'.time,
};
# setup admin user
{
    my $member = setup_user($admin);
    $member->add_to_roles({role => 'admin'});
}

my $mech = Test::WWW::Mechanize::Catalyst->new;

# login (4 tests)
{
    $mech->get_ok('/admin');
    $mech->title_like( qr/ログイン/ );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => $admin,
        }
    );
    $mech->title_like( qr/管理画面/ );
}

# add user (15 tests)
{
    my $new_user = +{
        mail => sprintf('test+%s@soffritto.org',time),
        password => 'testuser',
        nickname => 'テスト用ユーザー',
    };
    $mech->follow_link_ok({text => 'add'});
    $mech->title_like( qr/ユーザー編集/ );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => $new_user,
        }
    );
    $mech->follow_link_ok({text_regex => qr/$new_user->{nickname}/});
    $mech->form_number(1);
    is $mech->value('mail'), $new_user->{mail};
    is $mech->value('nickname'), $new_user->{nickname};

    # login with new user (9 tests)
    {
        my $mech_user = Test::WWW::Mechanize::Catalyst->new;
        $mech_user->get_ok('/');
        $mech_user->follow_link_ok({text => 'ログイン'});
        $mech_user->title_like(qr/ログイン/);
        $mech_user->submit_form_ok(
            {
                form_number => 1,
                fields => {
                    mail => $new_user->{mail},
                    password => $new_user->{password},
                }
            }
        );
        $mech_user->title_like( qr/メンバーページ/ );
        $mech_user->content_like( qr/$new_user->{nickname}さんのページ/ );
        $mech_user->follow_link_ok({text => 'トップページ'});
        $mech_user->title_is( '美食倶楽部（仮）' );
        $mech_user->follow_link_ok({text => "$new_user->{nickname}さんのページ"});
    }

    # delete user (2 tests)
    {
        ok $mech->click_button(value => 'delete');
        ok ! $mech->find_link(text_regex => qr/$new_user->{nickname}/);
    }

    # login with deleted user (5 tests)
    {
        my $mech_user = Test::WWW::Mechanize::Catalyst->new;
        $mech_user->get_ok('/');
        $mech_user->follow_link_ok({text => 'ログイン'});
        $mech_user->title_like( qr/ログイン/ );
        $mech_user->submit_form_ok(
            {
                form_number => 1,
                fields => {
                    mail => $new_user->{mail},
                    password => $new_user->{password},
                }
            }
        );
        $mech_user->content_like( qr/ログインできませんでした！/ );
    }
}
