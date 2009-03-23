use strict;
use t::Util;
use Test::More tests => 2;
BEGIN { use_ok 'GourmetSpot::Controller::Mobile' }

guest->get_ok( '/mobile', 'Request should succeed' );
