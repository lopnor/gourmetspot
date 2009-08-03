package GourmetSpot::Controller::Member;
use strict;
use warnings;
use parent 'GourmetSpot::ControllerBase::Resource';

__PACKAGE__->config(
    {
        model => 'DBIC::Member',
        rows => 0,
    }
);

1;
