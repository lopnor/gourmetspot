package GourmetClub::Model::DBIC;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'GourmetClub::Schema',
);

=head1 NAME

GourmetClub::Model::DBIC - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<GourmetClub>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<GourmetClub::Schema>

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
