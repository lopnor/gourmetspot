package GourmetSpot::View::TTMail;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt2',
    DEFAULT_ENCODING => 'utf8',
    DEBUG => 'all',
    PROVIDERS => [
        {
            name => 'Encoding',
            copy_config => [qw(DEFAULT_ENCODING INCLUDE_PATH PRE_CHOMP POST_CHOMP)],
        }
    ],
);

=head1 NAME

GourmetSpot::View::TTMail - TT View for GourmetSpot

=head1 DESCRIPTION

TT View for GourmetSpot. 

=head1 AUTHOR

=head1 SEE ALSO

L<GourmetSpot>

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
