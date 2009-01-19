package GourmetClub::ConfigLoader;
use strict;
use warnings;

use FindBin;
use Catalyst::Utils;
use Config::General;
use Path::Class qw/file dir/;

sub load {
    my $class = shift;

    my $bin = file($FindBin::Bin);
    my $config = { home => $bin->parent };
    for my $cfg ( qw/gourmetclub.conf gourmetclub_local.conf/ ) {
        my $c = eval {
            Config::General->new( $bin->parent->file($cfg) );
        } or next;

        $config = Catalyst::Utils::merge_hashes($config, +{ $c->getall() });
    }
    $config;
}

1;

