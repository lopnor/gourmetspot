package GourmetSpot::Worker;
use strict;
use warnings;
use GourmetSpot::Util;
use TheSchwartz;
use UNIVERSAL::require;

use Module::Pluggable 
    search_path => 'GourmetSpot::Worker',
    sub_name => 'workers',
    require => 1;

sub schwartz {
    my $class = shift;
    my $config = GourmetSpot::Util->load_config;

    my $schwartz = TheSchwartz->new(%{ $config->{'Model::TheSchwartz'}{args} });
    for my $w (GourmetSpot::Worker->workers) {
        $w->require;
        (my $config_name = $w) =~ s{^GourmetSpot::}{};
        $w->config($config->{$config_name});
        $schwartz->can_do($w);
    }
    return $schwartz;
}

1;
