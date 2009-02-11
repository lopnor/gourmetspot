package GourmetClub::Model::Geo;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'WebService::Simple',
    constructor => 'new',
    args        => {
        base_url => 'http://maps.google.com/maps/geo',
        param => {
            output => 'xml',
        },
    }
);

sub mangle_arguments {
    my ( $self, $args ) = @_;
    return %$args;
}

1;
