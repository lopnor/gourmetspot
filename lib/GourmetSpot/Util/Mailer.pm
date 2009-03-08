package GourmetSpot::Util::Mailer;
use strict;
use warnings;

sub is_available {
    local $@;
    eval "use TheSchwartz";
    return $@ ? 0 : 1;
}

sub send {
    my ($class, $message, %arg) = @_;
    require TheSchwartz;

    my $the_schwartz = TheSchwartz->new(%arg);
    $the_schwartz->insert(
        'GourmetSpot::Worker::Mailer',
        {
            message => $message,
        }
    );
    1;
}

1;
