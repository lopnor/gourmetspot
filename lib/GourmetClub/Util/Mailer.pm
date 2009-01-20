package GourmetClub::Util::Mailer;
use strict;
use warnings;

sub is_available {
    local $@;
    eval "use TheSchwartz";
    return $@ ? 0 : 1;
}

sub send {
    my ($class, $message, %arg) = @_;
    if (ref $arg{databases} eq 'HASH') {
        $arg{databases} = [ $arg{databases} ] ;
    }
    require TheSchwartz;

    my $the_schwartz = TheSchwartz->new(%arg);
    $the_schwartz->insert(
        'GourmetClub::Worker::Mailer',
        {
            message => $message,
        }
    );
    1;
}

1;
