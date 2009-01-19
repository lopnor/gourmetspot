package GourmetClub::Worker::Mailer;
use strict;
use warnings;
use utf8;
use base qw( TheSchwartz::Worker );
use Email::Send;
use Email::MIME;

sub work {
    my ( $class, $job ) = @_;

    my $message = $job->arg->{message};

    my $sender = Email::Send->new({mailer => 'Sendmail'});
    if ($sender->send($message)) {
        $job−>completed();
    } else {
        $job->failed('sending mail failed!',$@);
    }
}

1;
