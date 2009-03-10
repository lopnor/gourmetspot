use t::Util;
use Test::More tests => 16;

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};

my $mech = setup_user_and_login($user);

# move to account (2 tests)
{
    $mech->follow_link_ok({text => '招待／登録情報の変更など'});
    like( $mech->title, qr/アカウントセンター/ );
}

# change nickname (6 tests)
{
    $mech->follow_link_ok({text => '登録内容を変更する'});
    $mech->title_like( qr/登録内容の変更/ );
    $mech->form_number(1);
    is( $mech->value('nickname'), $user->{nickname} );
    $user->{nickname} = '変更後のニックネーム';
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => { nickname => $user->{nickname} },
        }
    );
    $mech->title_like( qr/アカウントセンター/ );
    ok( $mech->find_link(text => "$user->{nickname}さんのページ") );
}

# invalid change nickname (6 tests)
{
    $mech->get_ok('/account/edit');
    $mech->title_like( qr/登録内容の変更/ );
    $mech->form_number(1);
    is( $mech->value('nickname'), $user->{nickname} );
    $user->{nickname} = '変更後のニックネーム';
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => { nickname => '' },
        }
    );
    $mech->content_like( qr/ニックネームを入力してください。/ );
    ok( $mech->form_number(1) );
}

# change nickname without token (2 tests)
{
    $mech->post_ok('/account/edit', {nickname => 'hogehoge'});
    ok( $mech->form_number(1) );
} 
