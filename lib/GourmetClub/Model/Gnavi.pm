package GourmetClub::Model::Gnavi;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'GourmetClub::WebService::Gnavi',
    constructor => 'new',
);

sub mangle_arguments {
    my ( $self, $args ) = @_;
    return %$args;
}

1;
