use t::Util;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'GourmetSpot' }

guest->get_ok( '/', 'Request should succeed' );
