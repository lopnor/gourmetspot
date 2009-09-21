#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";
use GourmetSpot::Util;
use GourmetSpot::Schema;

use Getopt::Long;
use Term::ReadPassword;

GetOptions (
    "mail=s" => \(my $mail),
    "nickname=s" => \(my $nickname),
    "admin" => \(my $admin),
);

$mail && $nickname or die ;

my $password = read_password('password: ');
$password or die;

my $connect_info = GourmetSpot::Util->load_config
    ->{'Model::DBIC'}
    ->{'connect_info'};

my $schema = GourmetSpot::Schema->connect(@$connect_info);
my $member = $schema->resultset('Member')->create(
    {
        mail => $mail,
        nickname => $nickname,
        password => GourmetSpot::Util->compute_password($password),
    }
);
$member->add_to_roles({role => 'admin'}) if $admin;
