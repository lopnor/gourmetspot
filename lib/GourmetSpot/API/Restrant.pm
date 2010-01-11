package GourmetSpot::API::Restrant;
use Moose;
use GourmetSpot::API::Map;

*GourmetSpot::API::Restrant::distance_for_mysql = \&GourmetSpot::API::Map::distance_for_mysql;

sub search_with_coordinates {
    my ($self, $args) = @_;
    
    my $distance = $self->distance_for_mysql({point => $args->{coordinates}});

    my $cond = {$distance => { '<' => 5000} };

    my @restrant_id = $self->ids_narrow_down_by_tags($args);
    if (@restrant_id) {
        $cond->{id} = {in => \@restrant_id};
    }

    my $rs = $args->{resultset}->search(
        $cond,
        {
            '+select' => [
                "$distance as distance",
            ],
            order_by => 'distance',
            rows => $args->{rows} || 10,
        }
    );
}

sub ids_narrow_down_by_tags {
    my ($self, $args) = @_;
    my @restrant_id;
    if ($args->{tag_id}) {
        for my $id (@{$args->{tag_id}}) {
            my $cond = scalar @restrant_id ? {id => {in => \@restrant_id}} : {};
            my @related = $args->{resultset}->search( $cond, {select => 'id'})
                ->search_related('map_restrant_tag' => { tag_id => $id})->all;
            @restrant_id = map {$_->restrant_id} @related;
        }
    }
    return @restrant_id;
}

sub tags_nearby {
    my ($self, $args) = @_;

    my $distance = $self->distance_for_mysql({point => $args->{coordinates}});
    my $cond = { $distance => { '<' => 5000 } };
    my @restrant_id = $self->ids_narrow_down_by_tags($args);
    if (@restrant_id) {
        $cond->{id} = {in => \@restrant_id};
    }

    my @restrants = $args->{resultset}->search($cond)->all;

    return $self->tags_grouped(\@restrants, $args->{tag_id});
}

sub tags_grouped {
    my ($self, $rows, $existing) = @_;
    $rows = [ $rows ] unless ref $rows eq 'ARRAY';
    my @tags = map {$_->tags} @$rows;
    my %ret;
    for my $t (@tags) {
        next if grep {$_ == $t->id} @$existing;
        $ret{$t->value} and next;
        $ret{$t->value} = $t;
        $ret{$t->value}->{count} = $t->map_tag_review_rs(
            {restrant_id => {in => [ map {$_->id} @$rows ]} },
            {group_by => 'restrant_id'}
        )->count;
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
