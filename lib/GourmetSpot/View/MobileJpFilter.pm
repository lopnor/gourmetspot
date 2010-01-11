package GourmetSpot::View::MobileJpFilter;
use strict;
use warnings;
use base 'Catalyst::View::MobileJpFilter';

__PACKAGE__->config(
    {
        filters => [
            {
                module => 'DoCoMoCSS',
                config => {base_dir => GourmetSpot->path_to('root')},
            },
            {
                module => 'DoCoMoGUID',
                config => { abs => 1 },
            },
            {
                module => 'EntityReference',
                config => { force => 1 },
            },
        ]
    }
);

1;
