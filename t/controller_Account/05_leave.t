use t::Util;
use Test::More tests => 14;

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};

my $mech = setup_user_and_login($user);

# leave without token (3 tests)
{
    $mech->post_ok('/account/leave');
    ok( $mech->form_number(1) );
    $mech->get_ok('/account/');
}

# leave with invalid token (3 tests)
{
    $mech->post_ok('/account/leave', {_token => 'hogehoge'});
    ok( $mech->form_number(1) );
    $mech->get_ok('/account/');
}

# leave (8 tests)
{
    $mech->get_ok('/account');
    $mech->content_like(qr/$user->{nickname}さんのページ/);
    $mech->follow_link_ok({text => '退会する'});
    $mech->submit_form_ok(
        {
            form_number => 1,
        }
    );
    $mech->content_like(qr/退会処理が完了しました。/);
    is( $mech->uri->path, '/' );
    $mech->follow_link(text => 'ログイン');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => $user->{mail},
                password => $user->{password},
            }
        }
    );
    $mech->content_like(qr/ログインできませんでした！メールアドレスとパスワードをもう一度お確かめください！/);
}

