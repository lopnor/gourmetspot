package GourmetSpot::Util;
use strict;
use warnings;

use FindBin;
use Hash::Merge::Simple ();
use YAML;
use Path::Class qw(file dir);
use Digest::SHA1 qw(sha1_base64);

sub load_config {
    my $class = shift;

    my $bin = file($FindBin::Bin);
    my $config = { home => $bin->parent };
    for my $cfg ( qw/gourmetspot.yml gourmetspot_local.yml/ ) {
        my $c = eval {
            YAML::LoadFile( $bin->parent->file($cfg) );
        } or next;

        $config = Hash::Merge::Simple::merge($config, $c);
    }
    $config;
}

sub compute_password {
    my ( $class, $raw, $c ) = @_;
    my $config = $c ? $c->config : $class->load_config;
    my $credential = $config->{'Plugin::Authentication'}
                                ->{realms}
                                ->{members}
                                ->{credential};
    return sha1_base64(
        ($credential->{password_pre_salt} || '')
        . $raw
        . ($credential->{password_post_salt} || '')
    );
}

1;
