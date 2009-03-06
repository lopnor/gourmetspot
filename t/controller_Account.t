use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'GourmetSpot' }
BEGIN { use_ok 'GourmetSpot::Controller::Account' }

ok( request('/acount')->is_success, 'Request should succeed' );


