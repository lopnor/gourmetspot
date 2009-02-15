use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'GourmetClub' }
BEGIN { use_ok 'GourmetClub::Controller::Restrant' }

ok( request('/restrant')->is_success, 'Request should succeed' );

