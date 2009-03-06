use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'GourmetSpot' }
BEGIN { use_ok 'GourmetSpot::Controller::Restrant' }

ok( request('/restrant')->is_success, 'Request should succeed' );


