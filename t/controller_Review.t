use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'GourmetClub' }
BEGIN { use_ok 'GourmetClub::Controller::Review' }

ok( request('/review')->is_success, 'Request should succeed' );


