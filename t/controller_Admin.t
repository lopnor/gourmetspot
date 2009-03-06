use strict;
use warnings;
use utf8;
use Test::More tests => 8;

use Digest::SHA1 qw(sha1_base64);

BEGIN { use_ok 'Test::WWW::Mechanize::Catalyst', 'GourmetSpot' }
BEGIN { use_ok 'GourmetSpot::Controller::Admin' }
BEGIN { use_ok 'GourmetSpot::Schema' }
BEGIN { use_ok 'GourmetSpot::Util::ConfigLoader' }

my $config = GourmetSpot::Util::ConfigLoader->load;

my $schema = GourmetSpot::Schema->connect(
   @{ $config->{'Model::DBIC'}->{connect_info} }
);

my $salt = $config->{'Plugin::Authentication'}{realms}{members}{credential}{password_pre_salt};

my $account_info = {
    mail => 'test+'.time.'@soffritto.org',
    password => 'hogehoge',
};

my $member = $schema->resultset('Member')->create(
    {
        mail => $account_info->{mail},
        password => sha1_base64($salt . $account_info->{password}),
        nickname => 'test user '.scalar localtime,
    }
);

$member->add_to_roles({role => 'admin'});

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('/admin');
like $mech->title, qr/ログイン/;
$mech->submit_form_ok(
    {
        form_number => 1,
        fields => $account_info,
    }
);
like $mech->title, qr/管理画面/;
