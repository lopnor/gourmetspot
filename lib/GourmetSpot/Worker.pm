package GourmetSpot::Worker;
use strict;
use warnings;
use Module::Pluggable 
    search_path => 'GourmetSpot::Worker',
    sub_name => 'workers',
    require => 1;

1;
