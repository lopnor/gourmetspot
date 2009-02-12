package GourmetSpot::Util::ConfigLoader;
use strict;
use warnings;

use FindBin;
use Catalyst::Utils;
use YAML;
use Path::Class qw/file dir/;

sub load {
    my $class = shift;

    my $bin = file($FindBin::Bin);
    my $config = { home => $bin->parent };
    for my $cfg ( qw/gourmetspot.yml gourmetspot_local.yml/ ) {
        my $c = eval {
            YAML::LoadFile( $bin->parent->file($cfg) );
        } or next;

        $config = Catalyst::Utils::merge_hashes($config, $c);
    }
    $config;
}

1;

