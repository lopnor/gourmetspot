package GourmetClub::View::TTMail;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt2',
    DEFAULT_ENCODING => 'iso-2022-jp',
    DEBUG => 'all',
    PROVIDERS => [
        {
            name => 'Encoding',
            copy_config => [qw(DEFAULT_ENCODING INCLUDE_PATH PRE_CHOMP POST_CHOMP)],
        }
    ],
);

=head1 NAME

GourmetClub::View::TTMail - TT View for GourmetClub

=head1 DESCRIPTION

TT View for GourmetClub. 

=head1 AUTHOR

=head1 SEE ALSO

L<GourmetClub>

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
