package GourmetSpot::Controller::OpenHours;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::ControllerBase::Resource';

__PACKAGE__->config(
    {
        model => 'DBIC::OpenHours',
        preserve_token => 1,
    }
);

sub auto :Private {
    my ($self, $c) = @_;
    $c->stash->{current_view} = 'JSON';
    $self->next::method($c);
}

sub item_load :Chained :PathPrefix :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    $self->next::method($c, $id);
    $c->stash->{json_data} = +{ $c->stash->{item} ? $c->stash->{item}->get_columns : () };
}

sub index :Chained('noitem_load') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('setup_search_attr');
    my $rs = $c->model($self->{model})->search(
        $c->stash->{search_params},
        $c->stash->{search_attr},
    );

    $c->stash(
        list => [ $rs->all ],
        pager => $rs->pager,
        json_data => [ map { +{$_->get_columns} } $rs->all ]
    );
    $c->forward($c->view);
}

sub validate_token {
    my ( $self, $c ) = @_;
    $c->req->param('_token') or return;
    my $token = $c->session->{_token}; # don't delete because it will be called with AJAX
    $token or return;
    return $c->req->param('_token') eq $token;
}

=head1 NAME

GourmetSpot::Controller::OpenHours - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
