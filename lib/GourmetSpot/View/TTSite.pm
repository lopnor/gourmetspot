package GourmetSpot::View::TTSite;

use strict;
use base 'Catalyst::View::TT';
use GourmetSpot;

__PACKAGE__->config({
    INCLUDE_PATH => [
        GourmetSpot->path_to( 'root', 'src' ),
        GourmetSpot->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt2',
    ENCODING => 'utf8',
});

=head1 NAME

GourmetSpot::View::TTSite - Catalyst TTSite View

=head1 SYNOPSIS

See L<GourmetSpot>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

