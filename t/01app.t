use t::Util;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'GourmetSpot' }

ok( request('/')->is_success, 'Request should succeed' );
