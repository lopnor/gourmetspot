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
    my $c = GourmetSpot::Util::ConfigLoader->load;
    $config = $c->{'Model::TheSchwartz'};
    return;
}

sub gd_run {
    print "starting gourmetspot_worker";
    my $schwartz = TheSchwartz->new(%{ $config->{args} });
    for my $w (GourmetSpot::Worker->workers) {
        $w->require;
        $schwartz->can_do($w);
    }
    $schwartz->work();
}
