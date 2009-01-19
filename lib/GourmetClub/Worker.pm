package GourmetClub::Worker;
use strict;
use warnings;
use Module::Pluggable 
    search_path => 'GourmetClub::Worker',
    sub_name => 'workers',
    require => 1;

1;
