package GourmetSpot::Controller::Restrant;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::ControllerBase::Resource';

=head1 NAME

GourmetSpot::Controller::Restrant - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    {
        'model' => 'DBIC::Restrant',
        'like_fields' => ['name'],
        form => {
            name => [
                {
                    rule => 'NOT_BLANK',
                    message => 'お店の名前を入力してください',
                },
            ],
            latitude => [
                {
                    rule => 'NOT_BLANK',
                    message => '場所を地図で指定してください',
                },
            ],
            longitude => [
                {
                    rule => 'NOT_BLANK',
                    message => '場所を地図で指定してください',
                },
            ],
        }
    }
);

sub setup_item_params :Private {
    my ($self, $c) = @_;
    $self->next::method($c);
    if (my $outer = $c->stash->{outer_params}->{openhours}) {
        for my $item (@{$outer}) {
            $item or next;
            if ($item->{id}) {
                unless ($item->{holiday} || $item->{pre_holiday} || scalar $item->{day_of_week}) {
                    $item->{_delete} = 1;
                    next;
                }
            }
            $item->{holiday} ||= 0;
            $item->{pre_holiday} ||= 0;
            for (qw(opens_at closes_at)) {
                $item->{$_} = join(':', 
                    delete $item->{"${_}_hour"} || '00', 
                    delete $item->{"${_}_minute"} || '00',
                );
            }
        }
    }
}

#sub create_item :Private {
#    my ( $self, $c ) = @_;
#
#    $self->next::method($c);
#    $c->forward('update_openhours');
#}
#
#sub update_item :Private {
#    my ( $self, $c ) = @_;
#
#    $self->next::method($c);
#    $c->forward('update_openhours');
#}
#
#sub update_openhours :Private {
#    my ( $self, $c ) = @_;
#
#    $c->log->_dump( $c->stash->{outer_params} );
#
#    for my $item (@{$c->stash->{outer_params}->{'DBIC::OpenHours'}}) {
#        $item or next;
#        $item->{restrant_id} = $c->stash->{item}->id;
#        $item->{day_of_week} ||= [];
#        $item->{holiday} ||= 0;
#        $item->{pre_holiday} ||= 0;
#        for (qw(opens_at closes_at)) {
#            $item->{$_} = join(':', 
#                delete $item->{"${_}_hour"} || '00', 
#                delete $item->{"${_}_minute"} || '00',
#            );
#        }
#        if ($item->{holiday} || $item->{pre_holiday} || scalar $item->{day_of_week}) {
#            $c->model('DBIC::OpenHours')->update_or_create($item);
#        } else {
#            $c->model('DBIC::OpenHours')->find($item->{id})->delete if $item->{id};
#        }
#    }
#}

=head2 index

=cut

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
