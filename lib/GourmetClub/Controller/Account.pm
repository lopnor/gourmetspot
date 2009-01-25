package GourmetClub::Controller::Account;

use strict;
use warnings;
use utf8;
use parent 'Catalyst::Controller::RequestToken';
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
            && ($c->action ne 'account/login')
            && ($c->action ne 'account/password')
            && ($c->action ne 'account/join')) {
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

    $c->logout;

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
            $c->stash->{error} = 
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

    my $invitation_count = $c->model('DBIC::Invitation')->count(
        {
            caller_id => $c->user->id,
        },
    );
    warn $invitation_count;
    if ($invitation_count > 3) {
        $c->flash->{error} = '3人以上招待できません！';
        return $c->res->redirect($c->uri_for('./'));
    }
        
    $q->param('caller_name' => $c->user->nickname) 
        unless $q->param('caller_name');
    if ($q->method eq 'POST') {
        if ($q->param('confirm')) {
            $c->forward('invite_confirm');
        } elsif ($q->param('invite')) {
            $c->forward('invite_complete');
        }
    }
    $c->forward($c->view);
    $c->fillform;
}

sub invite_confirm :Private {
    my ($self, $c) = @_;

    my $mail = $c->req->param('mail');
    my ($exists) = $c->model('DBIC::Member')->search(
        {
            mail => $mail
        }
    );
    if ( $exists ) {
        $c->form->set_invalid('mail', 'NOT_REGISTERED');
    }
    if (!$c->form->has_error) {
        $c->forward('create_token');
        $c->stash->{template} = 'account/invite_confirm.tt2';
    }
}

sub invite_complete :Private {
    my ( $self, $c ) = @_;

    if ( $self->validate_token($c) ) {
        my $model = $c->model('DBIC::Invitation');
        my $mail = $c->req->param('mail');
        my $now = DateTime->now;
        my $invitation = $model->create({
                caller_id => $c->user->id,
                mail => $mail,
                nonce => sha1_base64($now . $mail . $c->user . rand),
                created_at => $now,
            });
        $c->stash(
            email => {
                to => $invitation->mail,
                template => 'invitation.tt2',
            },
            invitation => $invitation,
        );
        $c->forward( $c->view('Email') );
        $c->flash->{message} = '招待状をお送りしました！';
        $c->res->redirect($c->uri_for('./'));
    }
}

sub join :Path('join') {
    my ( $self, $c ) = @_;

    $c->logout;

    my ($invitation) = $c->model('DBIC::Invitation')->search(
        {
            id => $c->req->param('id'),
            nonce => $c->req->param('nonce'),
        }
    ) or return $c->res->redirect('/');
    if ( $invitation->member_id ) {
        $c->flash->{error} = '既に登録済みのようです';
        $c->res->redirect('/');
    }

    if ( $c->req->method eq 'POST') {
        if ( $c->req->param('confirm') ) {
            $c->forward('join_confirm', [ $invitation ] );
        } elsif ( $c->req->param('join') ) {
            $c->forward('join_complete', [ $invitation ] );
        }
    }
    $c->stash->{invitation} = $invitation;
    $c->forward($c->view);
    $c->fillform;
}

sub join_confirm :Private {
    my ( $self, $c, $invitation ) = @_;

    if ($c->req->param('password') ne $c->req->param('password_confirm')) {
        $c->form->set_invalid('password_confirm', 'SAME_AS_PASSWORD');
    }

    if ( !$c->form->has_error ) {
        $c->forward('create_token');
        $c->session->{_join_password} = $c->req->param('password');
        $c->stash->{template} = 'account/join_confirm.tt2';
    }
}

sub join_complete :Private {
    my ( $self, $c, $invitation ) = @_;

    my $password = delete $c->session->{_join_password} 
        or return $c->res->redirect('/');

    if ( $self->validate_token($c) ) {
        my $member = $c->model('DBIC::Member')->create(
            {
                caller_id => $invitation->caller_id,
                mail => $invitation->mail,
                nickname => $c->req->param('nickname'),
                password => $c->compute_password($password),
            }
        );
        $invitation->update({
                member_id => $member->id,
                joined_at => DateTime->now,
            });
        $c->stash(
            email => {
                to => $member->mail,
                template => 'join.tt2',
            },
            member => $member,
        );
        $c->forward( $c->view('Email') );

        $c->flash->{message} = '登録が完了しました！';
        $c->authenticate( {
                mail => $member->mail,
                password => $password,
            });
        $c->res->redirect($c->uri_for('./'));
    }
}

sub password :Path('password') {
    my ( $self, $c ) = @_;
    $c->logout;
    if ( $c->req->param('nonce') ) {
        my ($reset) = $c->model('DBIC::ResetPassword')->search(
            {
                id => $c->req->param('id'),
                nonce => $c->req->param('nonce'),
            }
        );
        if (!$reset) {
            $c->flash->{error} = 'パスワードの再設定URLが正しくありません。もう一度やってみてください。';
            return $c->res->redirect($c->uri_for('./password'));
        }
        if ($reset->expires_at->epoch < DateTime->now(time_zone => 'Asia/Tokyo')->epoch) {
            $reset->delete;
            $c->flash->{error} = 'パスワードの再設定URLが期限切れです。もう一度やってみてください。';
            return $c->res->redirect('./password');
        }
        if ($c->req->method eq 'POST') {
            $c->forward('password_reset', [ $reset ]);

        }
        $c->stash(
            template => 'account/password_reset.tt2',
            reset => $reset,
        );
        $c->forward($c->view);
        $c->fillform;
    } else {
        if ( $c->req->method eq 'POST') {
            if ($c->req->param('request')) {
                return $c->forward('password_request');
            }
        }
    }
}

sub password_request :Private {
    my ( $self, $c ) = @_;
    my $mail = $c->req->param('mail');
    my $member = $c->model('DBIC::Member')->find({mail => $mail});
    if ($member) {
        my $reset = $c->model('DBIC::ResetPassword')->create(
            {
                member_id => $member->id,
                expires_at => DateTime->now(time_zone => 'Asia/Tokyo')->add(minutes => 30),
                nonce => sha1_base64( $member->mail . time . rand ),
            }
        );
        $c->stash(
            email => {
                to => $member->mail,
                template => 'password.tt2',
            },
            member => $member,
            reset  => $reset,
        );
        $c->forward( $c->view('Email') );
    }
    $c->flash->{message} = '入力いただいたメールアドレスの登録があれば、パスワードをリセットする手順をメールでお伝えします。';
    return $c->res->redirect($c->uri_for('/'));
}

sub password_reset :Private {
    my ( $self, $c, $reset ) = @_;

    if ($c->req->param('password') ne $c->req->param('password_confirm')) {
        $c->form->set_invalid('password_confirm', 'SAME_AS_PASSWORD');
    }
    if (!$c->form->has_error) {
        my $password = $c->req->param('password');
        $reset->member->update(
            {
                password => $c->compute_password($password),
            }
        );
        $c->authenticate( {
                mail => $reset->member->mail,
                password => $password,
            });
        $reset->delete;
        $c->flash->{message} = 'パスワードを設定しました';
        return $c->res->redirect($c->uri_for('./'));
    }
}

sub create_token :Private {
    my ( $self, $c ) = @_;
    $c->session->{_token} = sha1_base64( $c->req . time . rand );
    $c->req->param('_token' => $c->session->{_token});
}

sub validate_token {
    my ( $self, $c ) = @_;
    my $token = delete $c->session->{_token} or return;
    return $c->req->param('_token') eq $token;
}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
