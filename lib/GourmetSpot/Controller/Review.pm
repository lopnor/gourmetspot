package GourmetSpot::Controller::Review;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::Base::Controller::Resource';
use MRO::Compat;
use DateTime;

=head1 NAME

GourmetSpot::Controller::Review - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    {
        model => 'DBIC::Review',
        outer_model => ['DBIC::Tag'],
        namespace => 'member/review',
        like_field => ['budget', 'comment'],
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
    $c->stash->{item_params}->{modified_at} = $now;
    $c->stash->{item_params}->{created_at} = $now;
    $c->stash->{item_params}->{created_by} = $c->user->id;
}

sub setup_item :Private {
    my ( $self, $c, $id) = @_;
    delete $c->stash->{item_params}->{created_at};
    delete $c->stash->{item_params}->{created_by};
    $self->next::method($c, $id);
}

sub create_item :Private {
    my ( $self, $c ) = @_;

    $self->next::method($c);
    $c->forward('update_tag');
}

sub update_item :Private {
    my ( $self, $c ) = @_;

    $self->next::method($c);
    $c->forward('update_tag');
}

sub update_tag :Private {
    my ( $self, $c ) = @_;
    my @values = split(/\s/, $c->stash->{outer_params}->{'DBIC::Tag'}->{value});
    my @tags = $c->stash->{item}->tags;
    for my $tag ($c->stash->{item}->tags) {
        if (grep {$_ eq $tag->value } @values) {
            @values = grep {$_ ne $tag->value} @values;
        } else {
            $tag->map_review_tag({review_id => $c->stash->{item}->id})->delete;
        } 
    }
    for my $value (@values) {
        my $tag = $c->model('DBIC::Tag')->find_or_create(
            {
                value => $value,
                created_at => $c->stash->{item}->created_by,
                created_at => $c->stash->{item}->created_at,
            },
            {
                key => 'value',
            }
        );
        $c->model('DBIC::TagReview')->find_or_create(
            {
                tag_id => $tag->id,
                review_id => $c->stash->{item}->id,
            }
        );
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
