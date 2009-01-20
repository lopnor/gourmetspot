package GourmetClub::View::Email::Template;

use strict;
use warnings;
use utf8;
use base 'Catalyst::View::Email::Template';
use Class::C3;
use Email::MIME::Modifier;
use Encode;

__PACKAGE__->config(
    stash_key       => 'email',
    template_prefix => ''
);

sub generate_part {
    my ( $self, $c, $attrs ) = @_;

    my $charset = $self->{default}->{charset} || 'utf8';

    my $mime = $self->next::method($c, $attrs);
    $mime->body_set(encode($charset, $mime->body));
    return $mime;
}

=head1 NAME

GourmetClub::View::Email::Template - Templated Email View for GourmetClub

=head1 DESCRIPTION

View for sending template-generated email from GourmetClub. 

=head1 AUTHOR

danjou

=head1 SEE ALSO

L<GourmetClub>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
