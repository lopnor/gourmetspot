package GourmetSpot::Controller::Tag;
use strict;
use warnings;
use parent 'GourmetSpot::ControllerBase::Resource';

__PACKAGE__->config(
    {
        model => 'DBIC::Tag',
        rows => 'all',
    }
);

1;
