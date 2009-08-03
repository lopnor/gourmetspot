use t::Util;
use Test::More tests => 51;

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};

my $mech = setup_user_and_login($user);

# change password without token (2 tests)
{
    $mech->post_ok('/account/password', {
            password => 'hogehoge',
            password_confirm => 'hogehoge',
        }
    );
    ok $mech->form_number(1);
}

# change password (12 tests)
{
    $mech->get('/account');
    $mech->follow_link_ok({text => '登録内容を変更する'});
    $mech->follow_link_ok({text => 'パスワードの変更はこちらで'});
    $mech->title_like( qr/パスワードの再設定/ );
    $user->{password} = 'newpasstest';
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                password => $user->{password},
                password_confirm => 'hogehoge',
            },
            button => 'reset',
        }
    );
    $mech->content_like( qr/パスワードが一致しません。/ );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                password => $user->{password},
                password_confirm => $user->{password},
            },
            button => 'reset',
        }
    );
    
    # login again
    {
        $mech->follow_link_ok({text => 'ログアウト'});
        $mech->title_is( '美食倶楽部（仮）' );
        $mech->follow_link_ok({text => 'ログイン'});
        $mech->title_like( qr/ログイン/);
        $mech->submit_form_ok(
            {
                form_number => 1,
                fields => {
                    mail => $user->{mail},
                    password => $user->{password},
                }
            }
        );
        ok( $mech->find_link(text => "$user->{nickname}さんのページ") );
    }
}

# login redirection (4 tests)
{
    $mech->get_ok('/account/logout');
    is( $mech->uri->path, '/' );
    $mech->get_ok('/account');
    is( $mech->uri->path, '/account/login' );
}

# invalid nonce (2 tests)
{
    my $guest = guest;
    $guest->get_ok('/account/password?nonce=invalidnonce&id=1');
    $guest->content_like(qr/パスワードの再設定URLが正しくありません。もう一度やってみてください。/);
}

# expired reset (6 tests)
{
    my $guest = guest;
    $guest->get('/account/login');
    $guest->follow_link(text => 'パスワードを忘れたら');
    {
        no strict 'refs';
        no warnings 'redefine';
        local *{"DateTime::now"} = sub {shift->from_epoch(epoch => time - (60 * 35), time_zone => 'Asia/Tokyo')};
        $guest->submit_form_ok(
            {
                form_number => 1,
                fields => {
                    mail => $user->{mail},
                },
                button => 'request',
            },
            'form for old expire'
        );
        $guest->content_like(qr/入力いただいたメールアドレスの登録があれば、パスワードをリセットする手順をメールでお伝えします。/);
    }
    ok( my $mail = mail_content );
    ok( my ($uri) = $mail =~ m{http://localhost(/account/password\?nonce=.+\&id=\d+?)} );
    $guest->get_ok($uri);
    $guest->content_like(qr/パスワードの再設定URLが期限切れです。もう一度やってみてください。/);
}

# mail input empty (2 tests)
{
    my $mech = guest;
    $mech->get('/account/password');
    $mech->submit_form_ok(
        {
            form_number => 1,
            button => 'request',
        }
    );
    $mech->content_like(qr/メールアドレスを入力してください/);
}

# invalid mail (3 tests)
{
    my $mech = guest;
    $mech->get('/account/password');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => 'hogehgeo@soffritto.org',
            },
            button => 'request',
        }
    );
    $mech->content_like(qr/入力いただいたメールアドレスの登録があれば、パスワードをリセットする手順をメールでお伝えします。/);
    ok( ! mail_content );
}

# post without token (2 tests)
{
    my $mech = guest;
    $mech->post_ok('/account/password', {mail => $user->{mail}, request => 1});
    ok( $mech->form_number(1) );
}

# post with invalid token (2 tests)
{
    my $mech = guest;
    $mech->post_ok('/account/password', {
            mail => $user->{mail}, 
            request => 1, 
            _token => 1
        }
    );
    ok( $mech->form_number(1) );
}

# valid mail (16 tests)
{
    my $mech = guest;
    $mech->get('/account/password');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => $user->{mail},
            },
            button => 'request',
        }
    );
    $mech->content_like(qr/入力いただいたメールアドレスの登録があれば、パスワードをリセットする手順をメールでお伝えします。/);
    ok( my $mail = mail_content );
    ok( my ($uri) = $mail =~ m{http://localhost(/account/password\?nonce=.+\&id=\d+?)} );

    # valid nonce
    $mech->get_ok($uri);
    $mech->content_like(qr/パスワードの再設定/);
    $mech->content_like(qr/$user->{mail}/);
    $user->{password} = 'forgotandset';
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                password => $user->{password},
                password_confirm => $user->{password},
            },
            button => 'reset',
        },
    );
    $mech->content_like(qr/パスワードを設定しました/);
    $mech->content_like(qr/$user->{nickname}さんのページ/);

    # oops! back button!

    $mech->back;
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                password => $user->{password},
                password_confirm => $user->{password},
            },
            button => 'reset',
        },
    );
    ok( $mech->form_number(1) );

    # login with new password
    $mech->get('/account/logout');
    $mech->get('/account/login');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => $user->{mail},
                password => $user->{password},
            }
        }
    );
    ok( $mech->find_link(text => "$user->{nickname}さんのページ") );

    # nonce already used = deleted nonce
    {
        my $mech = guest;
        $mech->get_ok($uri);
        $mech->content_like(qr/パスワードの再設定URLが正しくありません。もう一度やってみてください。/);
    }
}
