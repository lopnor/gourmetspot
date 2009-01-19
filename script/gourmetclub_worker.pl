#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use GourmetClub::ConfigLoader;
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
    my $c = GourmetClub::ConfigLoader->load;
    $config = $c->{'Model::TheSchwartz'};
    if (ref $config->{databases} eq 'HASH') {
        $config->{databases} = [ $config->{databases} ];
    }
    return;
}

sub gd_run {
    print "starting gourmetclub_worker",
    my $schwartz = TheSchwartz->new(%{ $config });
    for my $w (GourmetClub::Worker->workers) {
        $w->require;
        $schwartz->can_do($w);
    }
    $schwartz->work();
}
