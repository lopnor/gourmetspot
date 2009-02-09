package GourmetClub::Base::Controller::Resource;

use strict;
use warnings;
use parent qw(Catalyst::Controller);
use MRO::Compat;
use Digest::SHA1 qw(sha1_base64);

__PACKAGE__->config(
    {
        model => undef,
        search_field => '',
        form => undef,
        path => '',
    }
);

sub COMPONENT {
    my ( $class, $app_class, $config ) = @_;
    my $obj = $class->next::method(@_);

    return $obj;
}

sub _parse_PathPrefix_attr {
    my ( $self, $c, $name, $value ) = @_;
    return PathPart => $self->{path} || $self->path_prefix;
}

sub auto :Private {
    my ( $self, $c ) = @_;
    if ( !$c->user_in_realm('members') ) {
        $c->session->{backurl} = $c->req->uri;
        $c->res->redirect($c->uri_for('/account/login'));
        return 0;
    }
    return 1;
}

sub item_load :Chained :PathPrefix :CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $item = $c->model($self->{model})->find($id);

    unless ($item) {
        $c->res->body('not_found');
        return $c->res->status(404);
    }
    $c->stash(
        item => $item,
    );
    $c->forward('setup_item_params');
};

sub noitem_load :Chained :PathPrefix :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->forward('setup_item_params');
}

sub item :Chained('item_load') :PathPart('') :Args(0) { }

sub index :Chained('noitem_load') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    my $cond = {};
    if ( my $search_field = $self->{search_field} ) {
        if (my $q = $c->req->param($search_field)) {
            $cond->{$search_field} = {like => "%$q%"};
        }
    }
    my $rs = $c->model($self->{model})->search(
        $cond,
        {
            order_by => 'id desc',
            rows => 10,
            page => $c->req->param('page') || 1,
        },
    );

    $c->stash(
        list => [ $rs->all ],
        pager => $rs->pager,
    );
    $c->forward($c->view);
    $c->fillform;
}

sub add :Chained('noitem_load') :PathPart('add') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST' ) {
        $c->forward('validate_token');
        $c->form(
        );
        if ( ! $c->form->has_error && ! scalar @{$c->error} ) {
            my $item = $c->model($self->{model})->create($c->stash->{item_params});
            return $c->res->redirect( $c->uri_for( $item->id ) );
        }
        $c->clear_errors;
    }
    $c->forward('form');
}

sub edit :Chained('item_load') :PathPart('edit') :Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' ) {
        $c->forward('validate_token');
        if ( ! $c->form->has_error && ! scalar @{$c->error} ) {
            $c->stash->{item}->update($c->stash->{item_params});
        }
        $c->clear_errors;
        $c->res->redirect( $c->uri_for( $c->stash->{item}->id ) );
    }
    $c->forward('form');
}

sub remove :Chained('item_load') :PathPart('remove') Args(0) {
    my ( $self, $c ) = @_;
    
    if ( $c->req->method eq 'POST' ) {
        $c->forward('validate_token');
        if (scalar @{$c->error}) {
            $c->clear_errors;
        } else {
            $c->stash->{item}->delete;
        }
        return $c->res->redirect($c->uri_for('./'));
    }
    $c->forward('create_token');
    $c->forward( $c->view );
    $c->fillform;
}

sub setup_item_params :Private {
    my ( $self, $c ) = @_;
    my $params = {};
    map { $params->{$_} = $c->req->param($_) } 
        grep { $_ !~ /^[\.\_]/ }
        keys %{$c->req->params};
    $c->stash(
        item_params => $params,
    );
}

sub form :Private {
    my ($self, $c) = @_;

    $c->forward('create_token');
    $c->stash(
        template => $self->path_prefix . "/form.tt2",
    );
    $c->forward( $c->view );
    my $hash = $c->stash->{item} ? { $c->stash->{item}->get_columns }
                                 : $c->req->params;
    $hash->{_token} = $c->req->param('_token');
    $c->fillform($hash);
}

sub create_token :Private {
    my ( $self, $c ) = @_;
    $c->session->{_token} = sha1_base64( $c->req . time . rand );
    $c->req->param('_token' => $c->session->{_token});
}

sub validate_token :Private {
    my ( $self, $c ) = @_;
    my $token = delete $c->session->{_token};
    if (!$token || $c->req->param('_token') ne $token) {
        $c->error('validate_token error');
    }
}

1;
