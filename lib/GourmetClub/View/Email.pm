package GourmetClub::View::Email;

use strict;
use warnings;
use Carp;

use Class::C3;
use Email::MIME;
use Email::MIME::Modifier;
use base qw( Catalyst::View::Email::Template );

sub process {
    my ( $self, $c ) = @_;

    my $template_prefix         = $self->{template_prefix};
    my $default_view            = $self->{default}->{view};
    my $default_content_type    = $self->{default}->{content_type};
    my $default_charset         = $self->{default}->{charset};

    my $view;
    # if none specified use the configured default view
    if ($default_view) {
        $view = $c->view($default_view);
        $c->log->debug(__PACKAGE__ ." uses default view $view for rendering.") if $c->debug;
    }
    # else fallback to Catalysts default view
    else {
        $view = $c->view;
        $c->log->debug(__PACKAGE__ ." uses Catalysts default view $view for rendering.") if $c->debug;
    }


    # validate the per template view
    $self->_validate_view($view);

    my $stash_key = $self->{stash_key};
    # prefix with template_prefix if configured
    my $template = $c->stash->{$stash_key}->{template};
    $template =  join('/', $template_prefix, $template) if $template_prefix ne '';

    # render the email part
    my $output = $view->render( $c, $template, { 
            %{$c->stash},
        });

    if ( ref $output ) {
        croak $output->can('as_string') ? $output->as_string : $output;
    }

    my $email = Email::MIME->new($output);
    $email->body_set(Encode::encode('iso-2022-jp', $email->body));
    $email->header_set('Subject' => Encode::encode('MIME-Header-ISO_2022_JP', $email->header('Subject')));
    $email->header_set('To' => $c->stash->{$stash_key}->{to}) if $c->stash->{$stash_key}->{to};

    if ( $email ) {
        my $return = $self->mailer->send($email);
        # return is a Return::Value object, so this will stringify as the error
        # in the case of a failure.  
        croak "$return" if !$return;
    } else {
        croak "Unable to create message";
    }
}

1;
