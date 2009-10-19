package GourmetSpot::Schema::Tag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp Core));
__PACKAGE__->table("tag");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef,
        is_nullable => 0,
        size => 11 
    },
    value => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 255 
    },
    created_by => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
    created_at => {
        data_type => "DATETIME",
        default_value => undef,
        time_zone => 'Asia/Tokyo',
        set_on_create => 1,
        is_nullable => 1,
        size => 19,
    },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("value", ["value"]);

__PACKAGE__->has_many(
    'map_tag_review',
    'GourmetSpot::Schema::TagReview',
    'tag_id'
);
__PACKAGE__->many_to_many(
    'reviews',
    'map_tag_review',
    'review'
);
__PACKAGE__->many_to_many(
    'restrants',
    'map_tag_review',
    'restrant'
);

1;
