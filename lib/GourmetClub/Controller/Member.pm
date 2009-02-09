package GourmetClub::Controller::Member;

use strict;
use warnings;
use utf8;

use parent 'Catalyst::Controller';

=head1 NAME

GourmetClub::Controller::Member - Catalyst Controller

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


sub review :Path('review') :Args(0) {
    my ( $self, $c ) = @_;
    
    my $restrant;
    if (my $r_id = $c->req->param('restrant_id')) {
        $restrant = $c->model('DBIC::Restrant')->find({id => $r_id});
    }
    if ($c->req->method eq 'POST') {
        $c->forward('review_edit', [ $restrant ]);
    } 

    if (! $c->res->output ) {
        my @scene = $c->model('DBIC::Scene')->all;

        $c->stash(
            scene => \@scene,
            restrant => $restrant || undef,
        );
    }
}

sub review_edit :Private {
    my ( $self, $c, $restrant ) = @_;

    if ( !$c->form->has_error) {
        my $now = DateTime->now;

        my $review = $c->model('DBIC::Review')->create(
            {
                restrant_id => $restrant->id,
                budget => $c->req->param('budget'),
                scene_id => $c->req->param('scene_id'),
                comment => $c->req->param('comment'),
                created_by => $c->user->id,
                created_at => $now,
                modified_at => $now,
            }
        );
        return $c->res->redirect('review', $review->id);
    }
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

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
