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

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
