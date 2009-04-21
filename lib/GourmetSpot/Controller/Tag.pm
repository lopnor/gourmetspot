package GourmetSpot::Controller::Tag;
use strict;
use warnings;
use parent 'GourmetSpot::Base::Controller::Resource';

__PACKAGE__->config(
    {
        model => 'DBIC::Tag',
        rows => 0,
    }
);

1;
