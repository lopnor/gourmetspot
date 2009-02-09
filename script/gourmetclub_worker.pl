#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use GourmetClub::Util::ConfigLoader;
use GourmetClub::Worker;
use TheSchwartz;
use Daemon::Generic;
use UNIVERSAL::require;

newdaemon(
    progname   => 'gourmetclub_worker',
    pidfile    => '/tmp/groumetclub_worker.pid',
    configfile => "$FindBin::Bin/../gourmetclub.conf",
);

my $config;

sub gd_preconfig {
    my $self = shift;
    my $c = GourmetClub::Util::ConfigLoader->load;
    $config = $c->{'Model::TheSchwartz'};
    return;
}

sub gd_run {
    print "starting gourmetclub_worker";
    my $schwartz = TheSchwartz->new(%{ $config->{args} });
    for my $w (GourmetClub::Worker->workers) {
        $w->require;
        $schwartz->can_do($w);
    }
    $schwartz->work();
}
