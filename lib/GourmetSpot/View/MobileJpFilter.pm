package GourmetSpot::View::MobileJpFilter;
use strict;
use warnings;
use base 'Catalyst::View::MobileJpFilter';
use GourmetSpot;

__PACKAGE__->config(
    {
        filters => [
            {
                module => 'DoCoMoCSS',
                config => {base_dir => GourmetSpot->path_to('root')},
            },
            {
                module => 'DoCoMoGUID',
            },
            {
                module => 'EntityReference',
                config => { force => 1 },
            },
        ]
    }
);

sub process {
    my $self = shift;
    my $c = shift;
    $self->next::method( $c, @_);

    return 1;
}

1;
