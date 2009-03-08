use t::Util;
use Test::More tests => 3;

# use_ok (1 tests)
BEGIN { use_ok 'GourmetSpot::Controller::Root' }

# not found (2 tests)
{
    my $mech = setup_user_and_login;
    $mech->get('/hogehoge/fuga');
    is $mech->status, 404;
    $mech->content_like(qr/Page not found/);
}
