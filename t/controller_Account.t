use t::Util;
use Test::More tests => 47;

# use_ok (2 tests)
BEGIN { use_ok 'GourmetSpot::Controller::Account' }
BEGIN { use_ok 'GourmetSpot::Worker' }

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};

my $mech = setup_user_and_login($user);

# move to account (2 tests)
{
    $mech->follow_link_ok({text => '招待／登録情報の変更など'}, 'follow link to account page');
    like $mech->title, qr/アカウントセンター/;
}

# change nickname (6 tests)
{
    $mech->follow_link_ok({text => '登録内容を変更する'}, 'goto edit');
    like $mech->title, qr/登録内容の変更/;
    $mech->form_number(1);
    is $mech->value('nickname'), $user->{nickname};
    $user->{nickname} = '変更後のニックネーム';
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => { nickname => $user->{nickname} },
        }
    );
    like $mech->title, qr/アカウントセンター/;
    ok $mech->find_link(text => "$user->{nickname}さんのページ");
}

# change password (12 tests)
{
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
            }
        }
    );
    $mech->content_like( qr/パスワードが一致しません。/ );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                password => $user->{password},
                password_confirm => $user->{password},
            }
        }
    );
    
    # login again (6 tests)
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
        ok $mech->find_link(text => "$user->{nickname}さんのページ");
    }
}

# login redirection (4 tests)
{
    $mech->get_ok('/account/logout');
    is $mech->uri->path, '/';
    $mech->get_ok('/account');
    is $mech->uri->path, '/account/login';
}

# forgot password (18 tests)
{
    my $mail_path = config->{'Worker::Mailer'}{mailer_args}[0];
    unlink $mail_path;
    $mech->follow_link_ok({text => 'ログイン'});
    $mech->follow_link_ok({text => 'パスワードを忘れたら'});
    $mech->form_number(1);
    ok $mech->click_button(value => 'パスワードをリセットする');
    $mech->content_like(qr/メールアドレスを入力してください/);
    $mech->form_number(1);
    $mech->field(mail => $user->{mail});
    ok $mech->click_button(value => 'パスワードをリセットする');
    $mech->content_like(qr/入力いただいたメールアドレスの登録があれば、パスワードをリセットする手順をメールでお伝えします。/);
    ok my $worker = GourmetSpot::Worker->schwartz;
    isa_ok $worker, 'TheSchwartz';
    $worker->set_verbose(1);
    ok $worker->work_once();
    ok -r $mail_path;
    open my $fh , '<', $mail_path;
    binmode($fh, ':encoding(iso-2022-jp)');
    my $mail = do {local $/; <$fh>};
    close $fh;
    ok my ($uri) = $mail =~ m{http://localhost(/account/password\?nonce=.+\&id=\d+?)};
    $mech->get_ok($uri);
    $mech->content_like(qr/パスワードの再設定/);
    $mech->content_like(qr/$user->{mail}/);
    $user->{password} = 'forgotandset';
    $mech->form_number(1);
    $mech->field(password => $user->{password});
    $mech->field(password_confirm => $user->{password});
    ok $mech->click_button(value => 'パスワードを設定する');
    $mech->content_like(qr/パスワードを設定しました/);
    $mech->content_like(qr/$user->{nickname}さんのページ/);
}

# invite (5 tests)
{
    $mech->get_ok('/account');
    $mech->follow_link_ok({text => '招待する'});
    $mech->form_number(1);
    is $mech->value('caller_name'), $user->{nickname};
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                caller_name => '',
                name => '',
                mail => '',
                message => '',
            }
        }
    );
}
