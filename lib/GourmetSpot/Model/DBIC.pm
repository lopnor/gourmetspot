package GourmetSpot::Model::DBIC;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'GourmetSpot::Schema',
);

=head1 NAME

GourmetSpot::Model::DBIC - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<GourmetSpot>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<GourmetSpot::Schema>

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
