package GourmetClub::View::TTSite;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        GourmetClub->path_to( 'root', 'src' ),
        GourmetClub->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    TEMPLATE_EXTENSION => '.tt2',
    DEFULT_ENCODING => 'utf8',
    PROVIDERS => [
        {
            name => 'Encoding',
            copy_config => [qw(DEFAULT_ENCODING INCLUDE_PATH PRE_CHOMP POST_CHOMP)]
        },
    ],
});

=head1 NAME

GourmetClub::View::TTSite - Catalyst TTSite View

=head1 SYNOPSIS

See L<GourmetClub>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

