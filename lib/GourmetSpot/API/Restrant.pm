package GourmetSpot::API::Restrant;
use Moose;
use GourmetSpot::API::Map;

*GourmetSpot::API::Restrant::distance_for_mysql = \&GourmetSpot::API::Map::distance_for_mysql;

sub search_with_coordinates {
    my ($self, $args) = @_;
    
    my $distance = $self->distance_for_mysql({point => $args->{coordinates}});

    my $rs = $args->{resultset}->search(
        {
            $distance => { '<' => 5000},
        },
        {
            '+select' => [
                "$distance as distance",
            ],
            order_by => 'distance',
            rows => $args->{rows} || 5,
#            prefetch => ['reviews'],
        }
    );

}

sub tags_nearby {
    my ($self, $args) = @_;

    my $distance = $self->distance_for_mysql({point => $args->{coordinates}});

    my @restrants = $args->{resultset}->search(
        {
            $distance => { '<' => 5000},
        },
        {
            prefetch => 'reviews',
        },
    )->all;

    return $self->tags_grouped(@restrants);
}

sub tags_grouped {
    my ($self, @rows) = @_;

    my @tags = map {$_->tags} map {$_->reviews} @rows;
    my %ret;
    for (@tags) {
        $ret{$_->value} ||= $_;
        $ret{$_->value}->{count}++;

    }
    return sort {$b->{count} <=> $a->{count}} values %ret;
}

sub average_budget {
    my ($self, $row) = @_;
    my ($count, $total);
    for my $review ($row->reviews) {
        my $budget = $review->get_column('budget') or next;
        $count++;
        $total += $budget;
    }
    return sprintf("%d", $total/$count) if $count;
}

1;
__END__

=head1 NAME

GourmetSpot::API::Restrant - api for crud restrants.

=cut
