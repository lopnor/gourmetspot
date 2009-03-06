package GourmetSpot::Base::Controller::Resource;

use strict;
use warnings;
use utf8;
use parent qw(Catalyst::Controller);
use MRO::Compat;
use Digest::SHA1 qw(sha1_base64);

__PACKAGE__->config(
    {
        model => undef,
        outer_model => [],
        like_fields => [],
        form => undef,
        default_view => undef,
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
                    for my $endpoint (qw(update create)) {
                        my $action = $prefix ? "$prefix/$endpoint" : $endpoint;
                        $messages->{$action}{$param} ||= {};
                        $messages->{$action}{$param}{ $rule_name } = $rule->{message} if defined $rule->{message};
                    }
                    $rule = $rule->{rule};
                }
                elsif (ref $rule eq 'HASH' and defined $rule->{self_rule} ) {
                    for my $endpoint (qw(update create)) {
                        my $action = "$prefix/$endpoint";
                        $messages->{$action}{$param} ||= {};
                        $messages->{$action}{$param}{ $rule->{self_rule} } = $rule->{message} if defined $rule->{message};
                    }
                    delete $rules->[$i];
                }
                $i++;
            }
        }
        for my $endpoint (qw(update create)) {
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
        json_data => [ map { +{$_->get_columns} } $rs->all ],
    );
    $c->forward($self->{default_view} || $c->view);
    $c->fillform;
}

sub update_or_create :Chained('noitem_load') :PathPart('update_or_create') :Args(0) {
    my ( $self, $c ) = @_;
    my $item = $c->model($self->{model})->search(
        $c->stash->{search_params},
        {
            order_by => 'id desc',
            rows => 1,
        }
    )->single;
    $c->res->redirect( $item ? 
        $c->uri_for( $item->id, 'update' ) : $c->uri_for('create', $c->req->params) );
}

sub create :Chained('noitem_load') :PathPart('create') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        if ( ! $c->form->has_error ) {
            return $c->forward('create_item');
        }
    }
    $c->forward('form');
}

sub update :Chained('item_load') :PathPart('update') :Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        if ( ! $c->form->has_error ) {
            return $c->forward('update_item');
        }
    }
    $c->forward('form');
}

sub delete :Chained('item_load') :PathPart('delete') Args(0) {
    my ( $self, $c ) = @_;
    
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        $c->forward('delete_item');
        return $c->res->redirect($c->uri_for());
    }
    $c->forward('create_token');
    $c->forward( $self->{default_view} || $c->view );
    $c->fillform;
}

sub setup_item_params :Private {
    my ( $self, $c ) = @_;
    my $params = {};
    for my $key (grep { $_ !~ /^[\.\_]/ } keys %{$c->req->params}) {
        my @value = $c->req->param($key);
        my ($outer_model,$outer_key) = split(/\./, $key);
        if ($outer_model && $outer_key) {
            my $outer_index;
            if ($outer_model =~ s/\[(\d+)\]$//) {
                $outer_index = $1;
            }
            grep {$_ eq "DBIC::$outer_model"} @{$self->{outer_model}} or next;
            if ( defined $outer_index ) {
                $params->{outer}->{"DBIC::$outer_model"}->[$outer_index]->{$outer_key} 
                    = (scalar @value > 1) ? \@value : $value[0];
            } else {
                $params->{outer}->{"DBIC::$outer_model"}->{$outer_key}
                    = (scalar @value > 1) ? \@value : $value[0];
            }
        } else {
            $params->{item}->{$key}
                = (scalar @value > 1) ? \@value : $value[0];
            if ( grep {$_ eq $key} @{$self->{like_fields}} ) {
                $params->{search}->{$key} = {like => "%$value[0]%"};
            } else {
                $params->{search}->{$key}
                    = (scalar @value > 1) ? \@value : $value[0];
            }
        }
    }
    $c->stash(
        item_params => $params->{item},
        outer_params => $params->{outer},
        search_params => $params->{search},
    );
}

sub form :Private {
    my ($self, $c) = @_;

    $c->forward('create_token');
    $c->stash(
        template => $self->path_prefix . "/form.tt2",
    );
    $c->forward( $self->{default_view} || $c->view );
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
#    my $token = delete $c->session->{_token};
    my $token = $c->session->{_token};
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
        json_data => +{ $item->get_columns },
    );
}

sub update_item :Private {
    my ( $self, $c ) =@_;
    $c->stash->{item}->update($c->stash->{item_params});
    $c->res->redirect( $c->uri_for( $c->stash->{item}->id ) );
}

sub create_item :Private {
    my ( $self, $c ) =@_;
    my $item = $c->model($self->{model})->create($c->stash->{item_params});
    $c->stash->{item} = $item;
    return $c->res->redirect( $c->uri_for( $item->id ) );
}

sub delete_item :Private {
    my ( $self, $c ) =@_;
    $c->stash->{item}->delete;
}

1;
