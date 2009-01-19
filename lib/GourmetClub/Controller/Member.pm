package GourmetClub::Controller::Member;

use strict;
use warnings;
use utf8;
use parent 'Catalyst::Controller';
use DateTime;
use Digest::SHA1 qw(sha1_base64);
use Email::MIME::Creator;
use Encode;
use String::TT qw(strip tt);

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
    if (!$c->user_exists && ($c->req->uri ne $c->uri_for('login'))) {
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

    if (
        $c->authenticate( {
                mail => $c->req->param('mail'),
                password => $c->req->param('password'),
            })
    ) {
        my $uri = $c->session->{backurl} || $c->uri_for('./');
        $c->res->redirect($uri);
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
    if ($q->method eq 'POST') {
        my $now = DateTime->now;
        my ($mail, $name, $message);
        my $mail = $q->param('mail');
        my $name = $q->param('name');
        my $message = $q->param('message');
        my $caller = $c->user->nickname;
        my $nonce = sha1_base64($now, $mail, $c->user, rand);
        my $model = $c->model('DBIC::Invitation');
        my $invitation = $model->create({
                caller_id => $c->user->id,
                mail => $mail,
                nonce => $nonce,
                created_at => $now,
            });
        my $uriforjoin = $c->uri_for('join', {id => $invitation->id, nonce => $nonce});
        my $body = strip tt q{
            [% name %]様

            美食倶楽部に入りませんか？
            以下のURLをクリックしてください。
            [% uriforjoin %]

            [% caller %] さまからのメッセージです

            [% message %]
        };
        my $mime = Email::MIME->create(
            header => [
                To      => $mail,
                Subject => encode('MIME-Header-ISO_2022_JP', '美食倶楽部へのお誘い'),
                'Content-Type' => 'text/plain;charset=iso-2022-jp',
            ],
            body => encode('iso-2022-jp', $body),
        );

        $c->model('TheSchwartz')->insert(
            'GourmetClub::Worker::Mailer', 
            {
                message => $mime,
            },
        );
        $c->res->redirect('./');
    }
}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
