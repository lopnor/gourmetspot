use strict;
use warnings;
use Test::More tests => 2;

BEGIN { 
    use_ok('Catalyst::Test', 'GourmetSpot');
    use_ok('GourmetSpot::View::MobileJpFilter');
}
