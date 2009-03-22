use t::Util;
use Test::More tests => 6;

BEGIN { use_ok 'GourmetSpot::Controller::Member' }

my $user = +{
    mail => 'test@soffritto.org',
    password => 'testtest',
    nickname => 'テスト用ユーザー',
};

{
    my $mech = setup_user_and_login($user);
    $mech->get_ok('/member');
}
{
    my $mech = guest;
    $mech->get_ok('/member');
    is( $mech->uri->path, '/account/login' );
    $mech->submit_form_ok(
        {
            form_number => 1,
            fields => {
                mail => $user->{mail},
                password => $user->{password},
            },
        }
    );
    is( $mech->uri->path, '/member' );
}
