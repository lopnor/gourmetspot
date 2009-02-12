package GourmetSpot::Controller::Restrant;

use strict;
use warnings;
use parent 'GourmetSpot::Base::Controller::Resource';

use MRO::Compat;

=head1 NAME

GourmetSpot::Controller::Restrant - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub setup_item :Private {
    my ( $self, $c, $id ) = @_;
    $self->next::method($c, $id);
    my $geo = $c->model('Geo');
    my $res = $geo->get({q => $c->stash->{item}->address});
    if ($res->is_success) {
        my $p = $res->parse_response->{Response}{Placemark};
        my $coordinates = $p->{Point} ? $p->{Point}{coordinates} : $p->{p1}{Point}{coordinates};
        $c->stash(
            point => [ split (',', $coordinates) ]
        );
    }
}


=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
