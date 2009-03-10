use t::Util;
use Test::More tests => 76;

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};
my $new_user = {
    mail => 'new_user_to_invite@soffritto.org',
    nickname => '招待されたユーザー',
    password => 'hogehoge',
};
my $invitation = {
    caller_name => '招待者名',
    name => '招待メール宛先',
    mail => $new_user->{mail},
    message => '招待メッセージ',
};
my $join_url;

my $mech = setup_user_and_login($user);

# invalid form (6 tests)
{
    $mech->get('/account');
    $mech->follow_link_ok({text => '招待する'});
    $mech->form_number(1);
    is( $mech->value('caller_name'), $user->{nickname} );

    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                caller_name => '',
            },
            button => 'confirm',
        }
    );
    $mech->content_like(qr/お名前を入力してください。/);
    $mech->content_like(qr/メールアドレスを入力してください。/);
    $mech->content_like(qr/メッセージを入力してください。/);
}

# invite without token (3 tests)
{
    $mech->post_ok('/account/invite',$invitation);
    ok( $mech->form_number(1) );
    $mech->content_unlike( qr/確認して送信/ );
}

# invite without token in last phase (3 tests)
{
    $mech->get('/account/invite');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => $invitation,
            button => 'confirm',
        }
    );
    $mech->post_ok('/account/invite', {invite => 1});
    $mech->content_like(qr/確認画面にすすむ/);
}

# invalid nonce (2 tests)
{
    my $guest = guest;
    $guest->get_ok('/account/join?nonce=invalidnonce&id=100');
    is( $guest->uri->path, '/' );
}

# valid form (13 tests)
{
    $mech->get('/account/invite');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => $invitation,
            button => 'confirm',
        }
    );
    $mech->content_like(qr/確認して送信/);
    $mech->submit_form_ok(
        {
            form_number => 1,
            button => 'rewrite',
        }
    );
    $mech->form_number(1);
    for (keys( %{$invitation} )) {
        is( $mech->value($_), $invitation->{$_} );
    }
    $mech->submit_form_ok(
        {
            form_number => 1,
            button => 'confirm',
        }
    );
    $mech->content_like(qr/確認して送信/);
    $mech->submit_form_ok(
        {
            form_number => 1,
            button => 'invite',
        }
    );
    $mech->content_like(qr/招待状をお送りしました！/);
    ok( my $mail = mail_content );
    ok( ($join_url) = $mail =~ m{http://localhost(/account/join\?nonce=.+\&id=\d+?)} );
}

# valid nonce but without token (2 tests)
{
    my $mech = guest;
    $mech->post_ok($join_url, {
            nickname => $new_user->{nickname},
            password => $new_user->{password},
            password_confirm => $new_user->{password},
            confirm => 1,
        }
    );
    ok( $mech->form_number(1) );
}

# valid nonce but without token (2 tests)
{
    my $mech = guest;
    $mech->post_ok($join_url, {
            nickname => $new_user->{nickname},
            password => $new_user->{password},
            password_confirm => $new_user->{password},
            join => 1,
        }
    );
    is( $mech->uri->path, '/' );
}

# valid nonce but without token (6 tests)
{
    my $mech = guest;
    $mech->get_ok($join_url);
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                nickname => $new_user->{nickname},
                password => $new_user->{password},
                password_confirm => $new_user->{password},
            },
            button => 'confirm',
        }
    );
    $mech->title_like(qr/参加確認/);
    ok( $mech->form_number(1) );
    $mech->post_ok($join_url,{
            nickname => $new_user->{nickname},
            join => 1
        });
    ok($mech->form_number(1));
}

# valid nonce but validation failure (17 tests)
{
    my $mech_invited = guest;
    $mech_invited->get_ok($join_url);
    $mech_invited->title_like(qr/参加する/);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            button => 'confirm',
        }
    );
    $mech_invited->content_like(qr/ニックネームを入力してください。/);
    $mech_invited->content_like(qr/パスワードを入力してください。/);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            fields => {
                nickname => $new_user->{nickname},
                password => $new_user->{password},
                password_confirm => $new_user->{password}.'wrong',
            },
            button => 'confirm',
        }
    );
    $mech_invited->content_like(qr/パスワードが一致しません。/);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            fields => {
                nickname => $new_user->{nickname},
                password => $new_user->{password},
                password_confirm => $new_user->{password},
            },
            button => 'confirm',
        }
    );
    $mech_invited->title_like(qr/参加確認/);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            button => 'rewrite',
        }
    );
    $mech_invited->form_number(1);
    is( $mech_invited->value('nickname'), $new_user->{nickname} );
    is( $mech_invited->value('password'), '' );
    is( $mech_invited->value('password_confirm'), '' );
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            fields => {
                nickname => $new_user->{nickname},
                password => $new_user->{password},
                password_confirm => $new_user->{password},
            },
            button => 'confirm',
        }
    );
    $mech_invited->title_like(qr/参加確認/);
    $mech_invited->cookie_jar(undef);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            button => 'join',
        }
    );
    is($mech_invited->uri->path, '/');
    $mech_invited->content_unlike(qr/$new_user->{nickname}さんのページ/);
}

# valid nonce (12 tests)
{
    my $mech_invited = guest;
    $mech_invited->get_ok($join_url);
    $mech_invited->title_like(qr/参加する/);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            fields => {
                nickname => $new_user->{nickname},
                password => $new_user->{password},
                password_confirm => $new_user->{password},
            },
            button => 'confirm',
        }
    );
    $mech_invited->title_like(qr/参加確認/);
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            button => 'join',
        }
    );
    $mech_invited->content_like(qr/$new_user->{nickname}さんのページ/);
    $mech_invited->content_like(qr/登録が完了しました！/);
    is( $mech_invited->uri->path, '/account' );
    $mech_invited->follow_link_ok({text => 'ログアウト'});
    $mech_invited->follow_link_ok({text => 'ログイン'});
    $mech_invited->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => $new_user->{mail},
                password => $new_user->{password},
            }
        }
    );
    $mech_invited->content_like(qr/$new_user->{nickname}さんのページ/);
}

# invite already joined user (2 tests)
{
    $mech->get('/account/invite');
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => $invitation,
            button => 'confirm',
        }
    );
    $mech->content_like(qr/このメールアドレスの方はすでに登録済みのようです。/);
}

# join with nonce already used (2 tests)
{
    my $guest = guest;
    $guest->get_ok($join_url);
    $guest->content_like(qr/既に登録済みのようです/);
}

# invite 4 people (5 tests)
{
    for (1 .. 2) {
        $mech->get('/account/invite');
        $invitation->{mail} = "dummy_invitation+$_\@soffritto.org";
        $mech->submit_form_ok(
            {
                form_number => 1,
                fields => $invitation,
                button => 'confirm',
            }
        );
        $mech->submit_form_ok(
            {
                form_number => 1,
                button => 'invite',
            }
        );
    }
    $mech->get('/account/invite');
    $mech->content_like(qr/3人以上招待できません！/);
}
