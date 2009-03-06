use t::Util;
use Test::More tests => 2;

BEGIN { use_ok 'GourmetSpot::Controller::Restrant' }

my $mech = setup_user_and_login;
$mech->get_ok('/member/restrant');


