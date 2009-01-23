package GourmetClub::Controller::Member;

use strict;
use warnings;
use utf8;
use parent 'Catalyst::Controller';
use DateTime;
use Digest::SHA1 qw(sha1_base64);
use Encode;

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
    if (
            !$c->user_in_realm('members')
            && ($c->req->uri ne $c->uri_for('login'))
            && ($c->req->uri ne $c->uri_for('password'))) {
        $c->session->{backurl} = $c->req->uri;
        $c->res->redirect($c->uri_for('login'));
        return 0;
    }
    return 1;
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

}

sub login :Path('login') {
    my ( $self, $c ) = @_;

    if ($c->req->method eq 'POST') {
        if (
            $c->authenticate( {
                    mail => $c->req->param('mail'),
                    password => $c->req->param('password'),
                })
        ) {
            my $uri = $c->session->{backurl} || $c->uri_for('./');
            $c->res->redirect($uri);
        } else {
            $c->flash->{error} = 
            'ログインできませんでした！メールアドレスとパスワードをもう一度お確かめください！';
        }
    }
}

sub logout :Path('logout') {
    my ( $self, $c ) = @_;

    $c->logout;
    $c->res->redirect($c->uri_for('/'));
}

sub invite :Path('invite') {
    my ( $self, $c ) = @_;
    
    my $q = $c->req;
    my $flash = $c->flash->{invitation} || {};
    if ($q->method eq 'POST') {
        if ($q->param('confirm')) {
            return $c->forward('invite_confirm');
        } elsif ($q->param('invite')) {
            my $model = $c->model('DBIC::Invitation');
            my $now = DateTime->now;
            my $mail = $flash->{mail};
            my $invitation = $model->create({
                    caller_id => $c->user->id,
                    mail => $mail,
                    nonce => sha1_base64($now, $mail, $c->user, rand),
                    created_at => $now,
                });
            $c->stash->{email} = {
                to => $invitation->mail,
                template => 'invitation.tt2',
            };
            $c->forward( $c->view('Email::TemplateEntity') );
            warn 'here';
            $c->res->redirect('./');
        }
    }
    $c->forward($c->view);
    $c->fillform($flash);
}

sub invite_confirm :Private {
    my ($self, $c) = @_;

    if (!$c->form->has_error) {
        for (qw(mail name caller_name message)) {
            $c->flash->{invitation}->{$_} = $c->req->param($_);
        }
        $c->stash->{template} = 'member/invite_confirm.tt2';
    }
}

sub password :Path('password') {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST') {
        my $mail = $c->req->param('mail');
        my $member = $c->model('DBIC::Member')->find({mail => $mail});
    }
}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
