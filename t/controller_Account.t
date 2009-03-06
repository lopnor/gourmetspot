use t::Util;
use Test::More tests => 25;

BEGIN { use_ok 'GourmetSpot::Controller::Account' }

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

# invite (4 tests)
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
