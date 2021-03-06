package GourmetSpot::Controller::Restrant;

use strict;
use warnings;
use utf8;
use parent 'GourmetSpot::ControllerBase::Resource';
use Data::Page::Navigation;

=head1 NAME

GourmetSpot::Controller::Restrant - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

__PACKAGE__->config(
    {
        'model' => 'DBIC::Restrant',
        rows => 40,
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
        my $i = 0;
        while ($i <= $#{$outer}) {
            my $item = $outer->[$i];
            unless ($item) {
                splice(@$outer, $i, 1);
                next;
            }
            if ($item->{id}) {
                unless ($item->{holiday} || $item->{pre_holiday} || scalar $item->{day_of_week}) {
                    $item->{_delete} = 1;
                    $i++;
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
            $i++;
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
