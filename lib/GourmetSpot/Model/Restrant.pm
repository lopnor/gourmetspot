package GourmetSpot::Model::Restrant;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'GourmetSpot::API::Restrant',
    constructor => 'new',
    args => {},
);

1;
