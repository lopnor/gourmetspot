#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use GourmetSpot::Util::ConfigLoader;
use GourmetSpot::Worker;
use TheSchwartz;
use Daemon::Generic;
use UNIVERSAL::require;

newdaemon(
    progname   => 'gourmetspot_worker',
    pidfile    => '/tmp/groumetclub_worker.pid',
    configfile => "$FindBin::Bin/../gourmetspot.conf",
);

my $config;

sub gd_preconfig {
    my $self = shift;
    $config = GourmetSpot::Util::ConfigLoader->load;
    return;
}

sub gd_run {
    print "starting gourmetspot_worker";
    my $schwartz = TheSchwartz->new(%{ $config->{'Model::TheSchwartz'}{args} });
    for my $w (GourmetSpot::Worker->workers) {
        $w->require;
        (my $config_name = $w) =~ s{^GourmetSpot::}{};
        $w->config($config->{$config_name});
        $schwartz->can_do($w);
    }
    $schwartz->work();
}
