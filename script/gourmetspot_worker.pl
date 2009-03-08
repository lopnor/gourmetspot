#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use GourmetSpot::Worker;
use Daemon::Generic;

newdaemon(
    progname   => 'gourmetspot_worker',
    pidfile    => '/tmp/groumetclub_worker.pid',
    configfile => "$FindBin::Bin/../gourmetspot.conf",
);

sub gd_preconfig {
    my $self = shift;
    return;
}

sub gd_run {
    print "starting gourmetspot_worker";
    my $schwartz = GourmetSpot::Worker->schwartz;
    $schwartz->work();
}
