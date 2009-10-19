package GourmetSpot::Schema::Result::OpenHours;

use strict;
use warnings;

use base 'GourmetSpot::Schema::Result';

__PACKAGE__->load_components(qw(InflateColumn::DateTime Core));
__PACKAGE__->table("open_hours");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_nullable => 0, 
        is_auto_increment => 1,
        size => 11 
    },
    restrant_id => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
    day_of_week => { 
        data_type => "SET", 
        default_value => undef, 
        is_nullable => 1, 
        size => 27,
        extra => {
            list => [qw(
                Sun
                Mon
                Tue
                Wed
                Thu
                Fri
                Sat
            )],
        }
    },
    holiday => { 
        data_type => "ENUM", 
        default_value => "false", 
        is_nullable => 0, 
        size => 6,
        extra => {
            list => [qw(
                true
                false
                masked
            )]
        }
    },
    pre_holiday => { 
        data_type => "ENUM", 
        default_value => "false", 
        is_nullable => 0, 
        size => 6, 
        extra => {
            list => [qw(
                true
                false
                masked
            )]
        }
    },
    opens_at => { 
        data_type => "TIME", 
        default_value => undef, 
        is_nullable => 1, 
        time_zone => 'Asia/Tokyo',
        size => 8 
    },
    closes_at => { 
        data_type => "TIME", 
        default_value => undef, 
        is_nullable => 1, 
        time_zone => 'Asia/Tokyo',
        size => 8,
    },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->inflate_column(
    day_of_week => { 
        inflate => sub { +{ map {($_ => 1)} split( ',', $_[0] ) } },
        deflate => sub { join( ',', @{ $_[0] } ) },
    }
);

1;
