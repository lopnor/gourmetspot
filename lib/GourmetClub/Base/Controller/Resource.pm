package GourmetClub::Base::Controller::Resource;

use strict;
use warnings;
use parent qw(Catalyst::Controller);
use MRO::Compat;
use Digest::SHA1 qw(sha1_base64);

__PACKAGE__->config(
    {
        model => undef,
        like_fields => [],
        form => undef,
    }
);

sub COMPONENT {
    my ( $class, $c, $args ) = @_;

    my $self = $class->next::method($c, $args);

    if ( my $profile = $args->{form} ) {
        my $prefix = $self->path_prefix($c);
        my $config = $c->config->{validator};
        my $messages = $config->{messages};
        for my $param ( keys %$profile ) {
            my $rules = $profile->{$param} || [];

            my $i = 0;
            for my $rule (@$rules) {
                if ( ref $rule eq 'HASH' and defined $rule->{rule} ) {
                    my $rule_name = ref $rule->{rule} eq 'ARRAY' ? $rule->{rule}[0] : $rule->{rule};
                    for my $endpoint (qw(edit add)) {
                        my $action = "$prefix/$endpoint";
                        $messages->{$action}{$param} ||= {};
                        $messages->{$action}{$param}{ $rule_name } = $rule->{message} if defined $rule->{message};
                    }
                    $rule = $rule->{rule};
                }
                elsif (ref $rule eq 'HASH' and defined $rule->{self_rule} ) {
                    for my $endpoint (qw(edit add)) {
                        my $action = "$prefix/$endpoint";
                        $messages->{$action}{$param} ||= {};
                        $messages->{$action}{$param}{ $rule->{self_rule} } = $rule->{message} if defined $rule->{message};
                    }
                    delete $rules->[$i];
                }
                $i++;
            }
        }
        for my $endpoint (qw(edit add)) {
            my $action = "$prefix/$endpoint";
            $config->{profiles}->{$action} = $profile;
        }
    }

    return $self;
}

sub _parse_PathPrefix_attr {
    my ( $self, $c, $name, $value ) = @_;
    return PathPart => $self->path_prefix($c);
}

sub auto :Private {
    my ( $self, $c ) = @_;
    $c->forward('setup_item_params');
}

sub item_load :Chained :PathPrefix :CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    $c->forward('setup_item', [ $id ]);
};

sub noitem_load :Chained :PathPrefix :CaptureArgs(0) { }

sub item :Chained('item_load') :PathPart('') :Args(0) { }

sub index :Chained('noitem_load') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    my $rs = $c->model($self->{model})->search(
        $c->stash->{search_params},
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

    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        if ( ! $c->form->has_error ) {
            my $item = $c->model($self->{model})->create($c->stash->{item_params});
            return $c->res->redirect( $c->uri_for( $item->id ) );
        }
    }
    $c->forward('form');
}

sub edit :Chained('item_load') :PathPart('edit') :Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        if ( ! $c->form->has_error ) {
            $c->stash->{item}->update($c->stash->{item_params});
        }
        $c->res->redirect( $c->uri_for( $c->stash->{item}->id ) );
    }
    $c->forward('form');
}

sub remove :Chained('item_load') :PathPart('remove') Args(0) {
    my ( $self, $c ) = @_;
    
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        $c->stash->{item}->delete;
        return $c->res->redirect($c->uri_for('./'));
    }
    $c->forward('create_token');
    $c->forward( $c->view );
    $c->fillform;
}

sub setup_item_params :Private {
    my ( $self, $c ) = @_;
    my $params = {};
    my $search_params = {};
    for my $key (grep { $_ !~ /^[\.\_]/ } keys %{$c->req->params}) {
        my $value = $c->req->param($key);
        $params->{$key} = $value;
        if ( grep {$_ eq $key} @{$self->{like_fields}} ) {
            $search_params->{$key} = {like => "%$value%"};
        } else {
            $search_params->{$key} = $value;
        }
    }
    $c->stash(
        item_params => $params,
        search_params => $search_params,
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

sub validate_token {
    my ( $self, $c ) = @_;
    my $token = delete $c->session->{_token};
    return $token && ($c->req->param('_token') eq $token);
}

sub setup_item :Private {
    my ( $self, $c, $id ) = @_;
    my $item = $c->model($self->{model})->find($id);

    unless ($item) {
        $c->res->body('not_found');
        return $c->res->status(404);
    }
    $c->stash(
        item => $item,
    );
}

1;
