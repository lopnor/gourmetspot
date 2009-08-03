package GourmetSpot::ControllerBase::Resource;

use strict;
use warnings;
use utf8;
use parent qw(Catalyst::Controller);
use Path::Class ();
use Digest::SHA1 qw(sha1_base64);
use URI::Escape;

__PACKAGE__->config(
    {
        model => undef,
#        file_dir => undef,
        default_view => undef,
        rows => 10,
        like_fields => [],
#        form => undef,
    }
);

sub COMPONENT {
    my ( $class, $c, $args ) = @_;

    my $self = $class->next::method($c, $args);

    if ( my $profile = $self->{form} ) {
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
                        my $action = "$prefix/$endpoint";
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
        $c->uri_for( $item->id, 'edit' ) : $c->uri_for('create', $c->req->params) );
}

sub _parse_PathPrefix_attr {
    my ( $self, $c, $name, $value ) = @_;
    return PathPart => $self->path_prefix($c);
}

sub auto :Private {
    my ( $self, $c ) = @_;
    $c->forward('setup_item_params');
    1;
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
};

sub noitem_load :Chained :PathPrefix :CaptureArgs(0) { }

sub item :Chained('item_load') :PathPart('') :Args(0) { 
    my ( $self, $c ) = @_;
    unless ($c->res->output) {
        $c->forward($c->view);
    }
}

sub index :Chained('noitem_load') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('setup_search_attr');
    my $rs = $c->model($self->{model})->search(
        $c->stash->{search_params},
        $c->stash->{search_attr},
    );

    $c->stash(
        list => [ $rs->all ],
        pager => $rs->pager,
    );
    $c->forward($c->view);
    $c->fillform;
}

sub setup_search_attr :Private {
    my ($self, $c) = @_;
    my $order;
    if ( $order = $c->req->param('_order') ) {
        $order .= " desc" if $c->req->param('_desc');
    }
    my $attr = {
        order_by => $order || 'id desc',
        rows => $c->req->param('_rows') ||$self->{rows},
        page => $c->req->param('_page') || 1,
    };
    if ($c->req->param('_rows') && $c->req->param('_rows') eq 'all') {
        delete $attr->{rows};
        delete $attr->{page};
    }
    $c->stash->{search_attr} = $attr;
}

sub create :Chained('noitem_load') :PathPart('create') :Args(0) {
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        if ( ! $c->form->has_error ) {
            return $c->forward('add_item');
        }
    }
    $c->forward('form');
}

sub file :Chained('item_load') :PathPart('file') :Args(2) {
    my ( $self, $c, $field, $filename ) = @_;
    my $file_dir = $self->{file_dir};
    my $item = $c->stash->{item};
    $filename = Encode::decode('utf8', URI::Escape::uri_unescape($filename));
    unless ($file_dir && $item->result_source->has_column($field) && ($item->get_column($field) eq $filename)) {
        $c->res->body('not_found');
        return $c->res->status(404);
    }
#    my $filename = $item->get_column($field);

    my $file = Path::Class::file($file_dir, $item->result_source->name, $item->id, $field, $filename);
    unless ($file->stat()) {
        $c->res->body('not_found');
        return $c->res->status(404);
    }
    my $content = $file->slurp();

    # $c->_ext_to_type is defined in 'Catalyst::Plugin::Static::Simple'!!
    $c->res->content_type($c->_ext_to_type($file));
#    $c->res->header('Content-Disposition' => qq{attachment; filename="$filename"});
    $c->res->body($content);
}

sub update :Chained('item_load') :PathPart('update') :Args(0) {
    my ( $self, $c ) = @_;
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        if ( ! $c->form->has_error ) {
            return $c->forward('edit_item');
        }
    }
    $c->forward('form');
}

sub delete :Chained('item_load') :PathPart('delete') Args(0) {
    my ( $self, $c ) = @_;
    
    if ( $c->req->method eq 'POST' && $self->validate_token($c) ) {
        $c->stash->{item}->delete;
        return $c->res->redirect($c->uri_for());
    }
    $c->forward('create_token');
    $c->forward( $c->view );
    $c->fillform;
}

sub setup_item_params :Private {
    my ( $self, $c ) = @_;
    my $params = {};
    for my $key (grep { $_ !~ /^[\.\_]/ } keys %{$c->req->params}) {
        my @value = $c->req->upload($key) || $c->req->param($key);
        my ($outer_model,$outer_key) = split(/\./, $key);
        if ($outer_model && $outer_key) {
            my $outer_index;
            if ($outer_model =~ s/\[(\d+)?\]$//) {
                $outer_index = defined $1 ? "$1" : '';
            }
            $self->_has_relationship($c, $outer_model) or next;
            if ( defined $outer_index ) {
                if ($outer_index eq '') {
                    $params->{outer}->{$outer_model} = [
                        map { +{ $outer_key => $_ } } 
                        split(/\s/, (scalar @value > 1) ? \@value : $value[0])
                    ];
                } else {
                    $params->{outer}->{$outer_model}->[$outer_index]->{$outer_key}
                    = (scalar @value > 1) ? \@value : $value[0];
                }
            } else {
                $params->{outer}->{$outer_model} = [
                    $outer_key => (scalar @value > 1) ? \@value : $value[0]
                ];
            }
        } else {
            $c->model($self->{model})->result_source->has_column($key) or next;
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
        template => $self->path_prefix ? $self->path_prefix. '/form.tt2' : "form.tt2",
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
    $c->req->param('_token') or return;
    my $token = delete $c->session->{_token} or return;
    return $c->req->param('_token') eq $token;
}

sub add_item :Private {
    my ( $self, $c ) = @_;
    my $item = $c->model($self->{model})->create($self->_mangle_hash($c->stash->{item_params}));
    $self->_copy_uploads($item, $c->stash->{item_params});
    for my $rel ( keys %{$c->stash->{outer_params}} ) {
        if ($self->_is_many_to_many($c, $rel)) {
            $self->_set_many_to_many($c, $item, $rel);
        } else {
            for my $arg ( @{$c->stash->{outer_params}->{$rel}} ) {
                my $meth = "add_to_$rel";
                my $rel_row = $item->$meth($self->_mangle_hash($arg));
                $self->_copy_uploads($rel_row, $arg);
            }
        }
    }
    $c->stash->{item} = $item;
    return $c->res->redirect( $c->uri_for( $item->id ) );
}

sub edit_item :Private {
    my ( $self, $c ) = @_;
    my $item = $c->stash->{item};
    $item->update($self->_mangle_hash($c->stash->{item_params}));
    for my $rel ( keys %{$c->stash->{outer_params}} ) {
        if ($self->_is_many_to_many($c, $rel)) {
            $self->_set_many_to_many($c, $item, $rel);
        } else {
            my $rel_resultset = $c->model($self->{model})->related_resultset($rel);
            my @pk = $rel_resultset->result_source->primary_columns;
            for my $arg ( @{$c->stash->{outer_params}->{$rel}} ) {
                my %pk_hash = map {my $v = delete $arg->{$_};$v ? ($_ => $v) : ()} @pk;
                if (scalar %pk_hash) {
                    my $rel_row = $rel_resultset->find(\%pk_hash) or next;
                    if (delete $arg->{_delete}) {
                        $rel_row->delete;
                    } elsif (scalar %{$arg}) {
                        $rel_row->update($self->_mangle_hash($arg));
                        $self->_copy_uploads($rel_row, $arg);
                    }
                } else {
                    my $action = "add_to_$rel";
                    my $rel_row = $c->stash->{item}->$action($self->_mangle_hash($arg));
                    $self->_copy_uploads($rel_row, $arg);
                }
            }
        }
    }
    $c->res->redirect( $c->uri_for( $c->stash->{item}->id ) );
}

sub _mangle_hash {
    my ($self, $hash) = @_;
    return  {
        map {
            $_,
            (ref $hash->{$_} eq 'Catalyst::Request::Upload') 
            ? $hash->{$_}->filename : $hash->{$_}
        } keys %$hash
    };
}

sub _copy_uploads {
    my ($self, $item, $hash) = @_;
    my $file_dir = $self->{file_dir} or return;
    for my $arg (keys %$hash) {
        my $upload = $hash->{$arg};
        ref $upload eq 'Catalyst::Request::Upload' or next;
        my $dir = Path::Class::dir($file_dir, $item->result_source->name, $item->id, $arg);
        $dir->mkpath or next;
        $upload->copy_to(Path::Class::file($dir, $upload->filename));
    }
}

sub _has_relationship {
    my ($self, $c, $outer) = @_;

    my $model = $c->model($self->{model});
    $model->result_source->has_relationship($outer) and return 1;
    return $self->_is_many_to_many($c, $outer);
}

sub _is_many_to_many {
    my ($self, $c, $outer) = @_;

    my $model = $c->model($self->{model});
    return $model->result_class->can("set_$outer") ? 1 : 0;
}

sub _rel_rs {
    my ($self, $c, $item, $outer) = @_;
    my $meth = $c->model($self->{model})->result_class->can("${outer}_rs") or return;
    return $item->$meth->result_source->resultset;
}

sub _set_many_to_many {
    my ($self, $c, $item, $outer) = @_;
    my $rel_rs = $self->_rel_rs($c, $item, $outer);
    my @rel_rows;
    for my $arg ( @{$c->stash->{outer_params}->{$outer}} ) {
        my $row = $rel_rs->search($self->_mangle_hash($arg))->single
            || $rel_rs->create($self->_mangle_hash($arg));
        $self->_copy_uploads($row, $arg);
        push @rel_rows, $row;
    }
    my $meth = "set_$outer";
    $item->$meth(\@rel_rows);
}

1;
