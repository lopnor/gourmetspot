package GourmetSpot::Controller::Restrant;

use strict;
use warnings;
use parent 'GourmetSpot::Base::Controller::Resource';

use MRO::Compat;

=head1 NAME

GourmetSpot::Controller::Restrant - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub update_item :Private {
    my ( $self, $c ) = @_;

    $self->next::method($c);

    for my $item (@{$c->stash->{outer_params}->{'DBIC::OpenHours'}}) {
        $item->{restrant_id} = $c->stash->{item}->id;
        $item->{day_of_week} = join(',', @{$item->{day_of_week}});
        for (qw(opens_at closes_at)) {
            $item->{$_} = join(':', 
                delete $item->{"${_}_hour"} || '00', 
                delete $item->{"${_}_minute"} || '00',
            );
        }
        $c->model('DBIC::OpenHours')->update_or_create($item);
    }
}

=head2 index

=cut

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
