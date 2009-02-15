package GourmetSpot::Controller::Admin;

use strict;
use warnings;
use parent 'Catalyst::Controller';


=head1 NAME

GourmetSpot::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    $c->authenticate({}, 'admin');
    return 1;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $model = $c->model('DBIC::Member');
    my $rs = $model->search;
    
    $c->stash(
        member => [ $rs->all ],
    );
}

sub add :Path('add') {
    my ( $self, $c ) = @_;

    my $q = $c->req;
    if ($q->method eq 'POST') {
        my $model = $c->model('DBIC::Member');
        my $member = $model->create({
                mail => $q->param('mail'),
                nickname => $q->param('nickname'),
                password => $c->compute_password( $q->param('password') ),
            });
        $c->res->redirect($c->uri_for('./'));
    }
    $c->stash->{template} = 'admin/edit.tt2';
}

sub edit :Path('edit') :Args(1) {
    my ( $self, $c, $id ) = @_;

    my $member = $c->model('DBIC::Member')->find($id);
    
    my $q = $c->req;
    if ($q->method eq 'POST') {
        if ($q->param('delete')) {
            $member->delete;
        } else {
            my $hash = {};
            for (qw(mail nickname password)) {
                my $value = $q->param($_);
                $value = $c->compute_password( $value ) if $_ eq 'password';
                $hash->{$_} = $value if length $q->param($_);
            }
            $member->update($hash);
        }
        $c->res->redirect($c->uri_for('./'));
    }
    $c->forward($c->view);
    $c->fillform( {
            mail => $member->mail,
            nickname => $member->nickname,
        });
}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;