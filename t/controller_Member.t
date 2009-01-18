use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'GourmetClub' }
BEGIN { use_ok 'GourmetClub::Controller::Member' }

ok( request('/member')->is_success, 'Request should succeed' );


