package GourmetClub::Model::TheSchwartz;
use strict;
use warnings;
use base 'Catalyst::Model::Adaptor';

__PACKAGE__->config( 
    class       => 'TheSchwartz',
    constructor => 'new',
);

sub prepare_arguments {
    my ( $self, $app ) = @_;

    my $args = $app->config->{"Model::TheSchwartz"};
    if (ref $args->{databases} eq 'HASH') {
        $args->{databases} = [ $args->{databases} ];
    }
    return $args;
}

sub mangle_arguments {
    my ( $self, $args ) = @_;

    return %$args;
}

1;
