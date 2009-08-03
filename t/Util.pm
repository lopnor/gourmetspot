package t::Util;
use strict;
use warnings;
use utf8;
use Carp;
use Test::More;
use DBI;
use Data::Dumper;
use Digest::SHA1 qw/sha1_base64/;
use FindBin;
use File::Spec::Functions;
use GourmetSpot::Util;
use GourmetSpot::Schema;
use GourmetSpot::Worker;

sub import {
    my ( $class, %args ) = @_;
    my $caller = caller;
    strict->import;
    warnings->import;
    utf8->import;

    for (qw(teardown_database setup_user guest setup_user_and_login config mail_content schema)) {
        no strict 'refs';
        *{"$caller\::$_"} = \&{$_};
    }

    $ENV{CATALYST_CONFIG} = "t/config";
    require Test::WWW::Mechanize::Catalyst;
    Test::WWW::Mechanize::Catalyst->import('GourmetSpot');

    {
        no strict 'refs';
        *{"Test::WWW::Mechanize::Catalyst::post_with_token_ok"} = \&post_with_token_ok;
    }

    # http://www.sixapart.jp/techtalk/2006/10/dev-vox-test.html
    {
        no warnings 'redefine';
        *WWW::Mechanize::is_html = sub {
            my $self = shift;
            return defined $self->{ct} &&
                ($self->{ct} eq 'text/html' || $self->{ct} eq 'application/xhtml+xml');
            };
        my $update_html = \&WWW::Mechanize::update_html;
        *WWW::Mechanize::update_html = sub {
            my $self = shift;
            my $ct = $self->ct;
            $self->$update_html(@_);
            $self->{ct} = $ct;
        };

        my $_match_any_image_parms = \&WWW::Mechanize::_match_any_image_parms;
        *WWW::Mechanize::_match_any_image_parms = sub {
            my $self = shift;
            local $SIG{__WARN__} = sub {};
            $self->$_match_any_image_parms(@_);
        };

        require HTTP::Message;
        my $decoded_content = \&HTTP::Message::decoded_content;
        *HTTP::Message::decoded_content = sub {
            my ($self, %opt) = @_;
            my $ct = $self->header("Content-Type");
            $self->header("Content-Type" => 'text/html;charset=utf-8') if $ct eq 'application/xhtml+xml';
            my $content = $self->$decoded_content(%opt);
            $self->header("Content-Type" => $ct);
            return $content;
        };
    }

    $class->teardown_database($caller);
    $class->setup_database($caller);
}

BEGIN {
    my $builder = Test::More->builder;
    binmode($builder->output, ':utf8');
    binmode($builder->failure_output, ':utf8');
    binmode($builder->todo_output, ':utf8');
}

END {
    &teardown_database;
}

sub setup_database {
    my ( $class, $caller ) = @_;
    my $connect_info = &config->{'Model::DBIC'}->{connect_info};
    my @dsn = split(/;=/,(split(':', $connect_info->[0]))[2]);
    my %dsn = scalar @dsn == 1 ? (database => @dsn) : @dsn;
    open my $fh, catfile &config->{home}, 'gourmetspot.sql';
    my $sql = do {local $/; <$fh>};
    close $fh;
    my @cmd = (
        'mysql',
        -u => $connect_info->[1],
        $connect_info->[2] ? ( -p => $connect_info->[2] ) : (),
        $dsn{host} ? (-h => $dsn{host}) : (),
        $dsn{database},
    );
    open my $pipe, '|-', @cmd;
    print $pipe $sql;
    close $pipe;
}

sub setup_user {
    my ($class, $args);
    if ($_[1]) {
        ($class, $args) = @_;
    } else {
        $args = shift;
    }
    my $member = &schema->resultset('Member')->create(
        {
            mail => $args->{mail},
            password => GourmetSpot::Util->compute_password($args->{password}),
            nickname => $args->{nickname},
        }
    );
    return $member;
}

sub setup_user_and_login {
    my ($class, $args);
    if ($_[1]) {
        ($class, $args) = @_;
    } elsif (ref $_[0] eq 'HASH') {
        $args = shift;
    }
    $args ||= {
        mail => 'test@soffritto.org',
        password => 'testtest',
        nickname => 'テスト用ユーザー',
    };

    setup_user($args);
    my $mech = Test::WWW::Mechanize::Catalyst->new;
    $mech->get('/');
    $mech->follow_link(text => 'ログイン');
    $mech->submit_form(
        form_number => 1,
        fields => {
            mail => $args->{mail},
            password => $args->{password},
        },
    );
    return $mech;
}

sub guest {
    return Test::WWW::Mechanize::Catalyst->new;
}

sub teardown_database {
    my ( $class, $caller ) = @_;
    my $dbh = DBI->connect(@{&config->{'Model::DBIC'}->{connect_info}}) or die $@;
    for my $table (@{$dbh->selectall_arrayref('show tables')}) {
        $dbh->do("drop table $table->[0]");
    }
}

sub config {
    return GourmetSpot::Util->load_config;
}

sub schema {
    return GourmetSpot::Schema->connect(
        @{ &config->{'Model::DBIC'}->{connect_info} }
    );
}

sub mail_content {
    my $mail_path = &config->{'Worker::Mailer'}{mailer_args}[0];
    unlink $mail_path;
    my $mail = '';
    {
        local $SIG{__WARN__} = sub {};
        my $worker = GourmetSpot::Worker->schwartz;
        $worker->work_once;
    }
    if ( -r $mail_path ) {
        open my $fh , '<', $mail_path or croak $@;
        binmode($fh, ':encoding(iso-2022-jp)');
        $mail = do {local $/; <$fh>};
        close $fh;
        unlink $mail_path;
    }
    return $mail;
}

sub post_with_token_ok {
    my ($mech, $args) = @_;

    my $form = $mech->form_number($args->{form_number});
    my $token = $form->value('_token');
    my $action = $form->action;
    my %button = $args->{button} ? ($args->{button} => $form->value($args->{button})) : ();
    return $mech->post_ok($action, {
            %{$args->{fields}},
            _token => $token,
            %button,
        }
    );
}

1;
