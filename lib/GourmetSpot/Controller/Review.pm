package GourmetSpot::Controller::Review;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::ControllerBase::Resource';
use DateTime;
use Data::Page::Navigation;

=head1 NAME

GourmetSpot::Controller::Review - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    {
        model => 'DBIC::Review',
        rows => 40,
        like_field => ['budget', 'comment'],
        form => {
            budget => [
                {
                    rule => 'NOT_BLANK',
                    message => '予算を入力してください',
                },
            ],
            'tags[].value' => [
                {
                    rule => 'NOT_BLANK',
                    message => 'タグを入力してください',
                }
            ],
        },
    }
);

sub form :Private {
    my ( $self, $c ) = @_;

    my $restrant = $c->stash->{item};
    if (! $restrant && (my $restrant_id = $c->req->param('restrant_id'))) {
        $restrant = $c->model('DBIC::Restrant')->find($restrant_id);
    }
    if ($restrant) {
        $c->stash(
            restrant => $restrant,
        );
        $self->next::method($c);
    } else {
        $c->res->redirect($c->uri_for());
    }
}

sub setup_item_params :Private {
    my ( $self, $c ) = @_;
    $self->next::method($c);

    my $now = DateTime->now;
    $c->stash->{search_params}->{created_by} = $c->user->id;
    $c->stash->{item_params}->{created_by} = $c->user->id;
}

sub setup_item :Private {
    my ( $self, $c, $id) = @_;
    delete $c->stash->{item_params}->{created_at};
    delete $c->stash->{item_params}->{created_by};
    $self->next::method($c, $id);
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
