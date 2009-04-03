package GourmetSpot::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

GourmetSpot::Controller::Root - Root Controller for GourmetSpot

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub auto :Private {
    my ( $self, $c ) = @_;
    if ($c->action->namespace ne 'mobile' && ! $c->req->mobile_agent->is_non_mobile) {
        $c->res->redirect($c->uri_for('/mobile'));
        return 0;
    } elsif ( $c->action->namespace eq 'mobile' ) {
        return 1;
    } elsif ( !$c->user_in_realm('members') ) {
        if ( $c->action->reverse eq 'index' || $c->action->namespace eq 'account' ) {
            return 1;
        }
        $c->session->{backurl} = $c->req->uri;
        $c->res->redirect($c->uri_for('/account/login'));
        return 0;
    }
    return 1;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    if ( !$c->user_in_realm('members' )) {
        $c->forward('index_for_guest');
    }
}

sub index_for_guest :Private {
    my ( $self, $c ) = @_;
    $c->stash(
        template => 'index_for_guest.tt2',
    );
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
    
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
