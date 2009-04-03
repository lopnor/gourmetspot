use t::Util;
use Test::More tests => 13;

# use_ok (1 tests)
BEGIN { use_ok 'GourmetSpot::Controller::Root' }

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};

# user already login (5 tests)
{
    my $mech = setup_user_and_login($user);
    $mech->get_ok('/');
    my @forms = $mech->forms;
    is scalar @forms, 0;
    $mech->follow_link_ok({text => 'ログアウト'});
    $mech->get_ok('/');
    @forms = $mech->forms;
    is scalar @forms, 1;
}
# login (5 tests)
{
    my $mech = guest;
    $mech->get_ok('/');
    my @forms = $mech->forms;
    is scalar @forms, 1;
    is( $mech->uri->path, '/' );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => $user->{mail},
                password => $user->{password},
            },
        }
    );
    is( $mech->uri->path, '/' );
}
# not found (2 tests)
{
    my $mech = setup_user_and_login;
    $mech->get('/hogehoge/fuga');
    is $mech->status, 404;
    $mech->content_like(qr/Page not found/);
}
