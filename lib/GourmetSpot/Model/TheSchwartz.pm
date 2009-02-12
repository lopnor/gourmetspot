package GourmetSpot::Model::TheSchwartz;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'TheSchwartz',
    constructor => 'new',
);

sub mangle_arguments {
    my ( $self, $args ) = @_;
    return %$args;
}

1;
