package t::Util;
use strict;
use warnings;
use utf8;
use Test::More;
use DBI;
use Data::Dumper;
use Digest::SHA1 qw/sha1_base64/;
use File::Spec::Functions;
use GourmetSpot::Util;
use GourmetSpot::Schema;
use Test::WWW::Mechanize::Catalyst qw/GourmetSpot/;

sub import {
    my ( $class, %args ) = @_;
    my $caller = caller;
    strict->import;
    warnings->import;
    utf8->import;

    for (qw(teardown_database setup_user setup_user_and_login)) {
        no strict 'refs';
        *{"$caller\::$_"} = \&{$_};
    }

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
    my $config = GourmetSpot::Util->load_config;
    my $connect_info = $config->{'Model::DBIC'}->{connect_info};
    my @dsn = split(/;=/,(split(':', $connect_info->[0]))[2]);
    my %dsn = scalar @dsn == 1 ? (database => @dsn) : @dsn;
    open my $fh, catfile $config->{home}, 'gourmetspot.sql';
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
    my $config = GourmetSpot::Util->load_config;
    my $schema = GourmetSpot::Schema->connect(
        @{ $config->{'Model::DBIC'}->{connect_info} }
    );
    my $member = $schema->resultset('Member')->create(
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

sub teardown_database {
    my ( $class, $caller ) = @_;
    my $config = GourmetSpot::Util->load_config;
    my $dbh = DBI->connect(@{$config->{'Model::DBIC'}->{connect_info}}) or die $@;
    for my $table (@{$dbh->selectall_arrayref('show tables')}) {
        $dbh->do("drop table $table->[0]");
    }
}

1;
