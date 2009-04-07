package GourmetSpot::Model::Map;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'GourmetSpot::API::Map',
    constructor => 'new',
    args => {},
);

1;
