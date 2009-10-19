package GourmetSpot::Schema::Result::Review;

use strict;
use warnings;

use base 'GourmetSpot::Schema::Result';

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp Core));
__PACKAGE__->table("review");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_auto_increment => 1,
        is_nullable => 0, 
        size => 11 
    },
    restrant_id => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
    budget => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11
    },
    comment => {
        data_type => "TEXT",
        default_value => undef,
        is_nullable => 1,
        size => 65535,
    },
    created_by => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
    created_at => {
        data_type => "DATETIME",
        timezone => 'Asia/Tokyo',
        set_on_create => 1,
        default_value => undef,
        is_nullable => 1,
        size => 19,
    },
    modified_at => {
        data_type => "DATETIME",
        timezone => 'Asia/Tokyo',
        set_on_create => 1,
        set_on_update => 1,
        default_value => undef,
        is_nullable => 1,
        size => 19,
    },
);
__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(
    'restrant',
    'GourmetSpot::Schema::Result::Restrant',
    'restrant_id'
);
__PACKAGE__->belongs_to(
    'member',
    'GourmetSpot::Schema::Result::Member',
    'created_by'
);
__PACKAGE__->has_many(
    'map_review_tag',
    'GourmetSpot::Schema::Result::TagReview',
    'review_id'
);
__PACKAGE__->many_to_many(
    'tags',
    'map_review_tag',
    'tag'
);

1;
