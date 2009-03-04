package GourmetSpot::Controller::Restrant;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::Base::Controller::Resource';

use MRO::Compat;

=head1 NAME

GourmetSpot::Controller::Restrant - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    {
        'model' => 'DBIC::Restrant',
        'outer_model' => ['DBIC::OpenHours'],
        'namespace' => 'member/restrant',
        'like_fields' => ['name'],
    }
);

sub create_item :Private {
    my ( $self, $c ) = @_;

    $self->next::method($c);
    $c->forward('update_openhours');
}

sub update_item :Private {
    my ( $self, $c ) = @_;

    $self->next::method($c);
    $c->forward('update_openhours');
}

sub update_openhours :Private {
    my ( $self, $c ) = @_;

    for my $item (@{$c->stash->{outer_params}->{'DBIC::OpenHours'}}) {
        $item or next;
        $item->{restrant_id} = $c->stash->{item}->id;
        $item->{day_of_week} = 
            ref $item->{day_of_week} ? join(',', @{$item->{day_of_week}}) : 
                ($item->{day_of_week} || '');
        $item->{holiday} ||= 0;
        $item->{pre_holiday} ||= 0;
        for (qw(opens_at closes_at)) {
            $item->{$_} = join(':', 
                delete $item->{"${_}_hour"} || '00', 
                delete $item->{"${_}_minute"} || '00',
            );
        }
        if ($item->{holiday} || $item->{pre_holiday} || $item->{day_of_week}) {
            $c->model('DBIC::OpenHours')->update_or_create($item);
        } else {
            $c->model('DBIC::OpenHOurs')->find($item->{id})->delete if $item->{id};
        }
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
