package GourmetSpot::Controller::Review;

use strict;
use warnings;
use parent 'GourmetSpot::Base::Controller::Resource';
use MRO::Compat;
use DateTime;

=head1 NAME

GourmetSpot::Controller::Review - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub form :Private {
    my ( $self, $c ) = @_;

    if (my $restrant_id = $c->req->param('restrant_id')) {
        my $restrant = $c->model('DBIC::Restrant')->find($restrant_id);
        $c->stash(
            restrant => $restrant || undef,
        );
    }
    $c->stash(
        scene => [ $c->model('DBIC::Scene')->all ]
    );
    $self->next::method($c);
}

sub setup_item_params :Private {
    my ( $self, $c ) = @_;
    $self->next::method($c);

    my $now = DateTime->now;
    $c->stash->{search_params}->{created_by} = $c->user->id;
    $c->stash->{item_params}->{modified_at} = $now;
    if ( ! $c->stash->{item} ) {
        $c->stash->{item_params}->{created_at} = $now;
        $c->stash->{item_params}->{created_by} = $c->user->id;
    }
}

=head2 index

=cut

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
