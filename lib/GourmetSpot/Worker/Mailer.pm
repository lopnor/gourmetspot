package GourmetSpot::Worker::Mailer;
use strict;
use warnings;
use utf8;
use base qw( TheSchwartz::Worker Class::Data::Inheritable );
use Email::Send;
use Email::MIME;

__PACKAGE__->mk_classdata('config');

sub work {
    my ( $class, $job ) = @_;

    my $message = $job->arg->{message};

    my $sender = Email::Send->new($class->config);
    my $result = $sender->send($message);
    if ($result) {
        $job->completed();
    } else {
        $job->failed('sending mail failed!',$result);
    }
}

1;
