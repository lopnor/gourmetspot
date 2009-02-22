package GourmetSpot::Controller::Member;

use strict;
use warnings;
use utf8;

use parent 'Catalyst::Controller';

=head1 NAME

GourmetSpot::Controller::Member - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub auto :Private {
    my ( $self, $c ) = @_;
    if ( !$c->user_in_realm('members') ) {
        $c->session->{backurl} = $c->req->uri;
        $c->res->redirect($c->uri_for('/account/login'));
        return 0;
    }
    return 1;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

sub scene : Path('scene') {
    my ( $self, $c ) = @_;
    
    my $scene = $c->model('DBIC::Scene')->create(
        {
            value => $c->req->param('value'),
            created_by => $c->user->id,
            created_at => DateTime->now,
        }
    );
    $c->stash(
        id => $scene->id,
        value => $scene->value,
    );
    $c->forward('View::JSON');
}

sub openhours :Path('openhours') {
    my ( $self, $c ) = @_;

    my @hours = $c->model('DBIC::OpenHours')->search(
        {
            restrant_id => $c->req->param('restrant_id'),
        }
    )->all;
    my @value = map { +{ $_->get_columns} } @hours;
    $c->stash(
        hours => \@value,
    );
    $c->forward('View::JSON');
}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
