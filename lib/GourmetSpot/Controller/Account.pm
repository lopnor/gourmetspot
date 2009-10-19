package GourmetSpot::Controller::Account;

use strict;
use warnings;
use utf8;
use parent 'Catalyst::Controller';
use DateTime;
use Digest::SHA1 qw(sha1_base64);
use GourmetSpot::Util;

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
            my $uri = $c->session->{backurl} ? $c->session->{backurl} : $c->uri_for('/');
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
    if ($invitation_count >= 3) {
        $c->flash->{error} = '3人以上招待できません！';
        return $c->res->redirect($c->uri_for());
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
#                created_at => $now,
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
        $c->res->redirect($c->uri_for());
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
        return $c->res->redirect('/');
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
                password => GourmetSpot::Util->compute_password($password, $c),
            }
        );
        $invitation->update({
                member_id => $member->id,
                joined_at => DateTime->now(time_zone => 'Asia/Tokyo'),
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
        $c->res->redirect($c->uri_for());
    }
}

sub password :Path('password') {
    my ( $self, $c ) = @_;

    if ( !$c->user_in_realm('members') ) {
        $c->forward('password_guest');
    } else {
        if ($c->req->method eq 'POST') {
            $c->forward('password_reset');
        }
        $c->stash(
            template => 'account/password_reset.tt2',
            member => $c->user,
        );
    }
    $c->forward('create_token');
    $c->forward($c->view);
    $c->fillform;
}

sub password_guest :Private {
    my ( $self, $c ) = @_;

    if ( $c->req->param('nonce') ) {
        my ($reset) = $c->model('DBIC::ResetPassword')->search(
            {
                id => $c->req->param('id'),
                nonce => $c->req->param('nonce'),
            }
        );
        if (!$reset) {
            $c->flash->{error} = 'パスワードの再設定URLが正しくありません。もう一度やってみてください。';
            return $c->res->redirect($c->uri_for('password'));
        }
        if ($reset->expires_at->epoch < DateTime->now(time_zone => 'Asia/Tokyo')->epoch) {
            $reset->delete;
            $c->flash->{error} = 'パスワードの再設定URLが期限切れです。もう一度やってみてください。';
            return $c->res->redirect('password');
        }
        if ($c->req->method eq 'POST') {
            $c->forward('password_reset', [ $reset ]);
        }
        $c->stash(
            template => 'account/password_reset.tt2',
            member => $reset->member,
        );
    } else {
        if ( $c->req->method eq 'POST') {
            return $c->forward('password_request');
        }
    }
}

sub password_request :Private {
    my ( $self, $c ) = @_;
    if (! $c->form->has_error && $self->validate_token($c) ) {
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
}

sub password_reset :Private {
    my ( $self, $c, $reset ) = @_;

    if ($self->validate_token($c)) {
        if ($c->req->param('password') ne $c->req->param('password_confirm')) {
            $c->form->set_invalid('password_confirm', 'SAME_AS_PASSWORD');
        }
        if (!$c->form->has_error) {
            my $member = $c->user ? $c->user : $reset->member;
            my $password = $c->req->param('password');
            $member->update(
                {
                    password => GourmetSpot::Util->compute_password($password, $c),
                }
            );
            if ( !$c->user ) {
                $c->authenticate( {
                        mail => $reset->member->mail,
                        password => $password,
                    });
                $reset->delete;
            }
            $c->flash->{message} = 'パスワードを設定しました';
            return $c->res->redirect($c->uri_for());
        }
    }
}

sub edit :Path('edit') {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' ) {
        $c->forward('edit_commit');
    }
    $c->req->param(nickname => $c->user->nickname) unless $c->req->param('nickname');
    $c->forward('create_token');
    $c->forward( $c->view );
    $c->fillform;
}

sub edit_commit :Private {
    my ( $self, $c ) = @_;
    if (!$c->form->has_error && $self->validate_token($c)) {
        $c->user->update(
            {
                nickname => $c->req->param('nickname'),
            }
        );
        $c->res->redirect($c->uri_for());
    }
}

sub leave :Path('leave') {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        $c->user->delete;
        $c->logout;
        $c->flash->{message} = '退会処理が完了しました。';
        return $c->res->redirect($c->uri_for('/'));
    }
    $c->forward('create_token');
    $c->forward( $c->view );
    $c->fillform;
}

sub create_token :Private {
    my ( $self, $c ) = @_;
    $c->session->{_token} = sha1_base64( $c->req . time . rand );
    $c->req->param('_token' => $c->session->{_token});
}

sub validate_token {
    my ( $self, $c ) = @_;
    my $token = delete $c->session->{_token} or return;
    $c->req->param('_token') or return;
    return $c->req->param('_token') eq $token;
}

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
