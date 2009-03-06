use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'GourmetSpot' }
BEGIN { use_ok 'GourmetSpot::Controller::Review' }

ok( request('/review')->is_success, 'Request should succeed' );


