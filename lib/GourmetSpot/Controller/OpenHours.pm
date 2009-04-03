package GourmetSpot::Controller::OpenHours;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::Base::Controller::Resource';

use MRO::Compat;

__PACKAGE__->config(
    {
        model => 'DBIC::OpenHours',
#        namespace => 'member/open_hours',
#        namespace => 'my/open_hours',
        default_view => 'View::JSON',
        preserve_token => 1,
    }
);

=head1 NAME

GourmetSpot::Controller::OpenHours - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
