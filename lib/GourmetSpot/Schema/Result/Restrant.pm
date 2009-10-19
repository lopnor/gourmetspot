package GourmetSpot::Schema::Result::Restrant;

use strict;
use warnings;

use base 'GourmetSpot::Schema::Result';

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp Core));
__PACKAGE__->table("restrant");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_auto_increment => 1,
        is_nullable => 0, 
        size => 11
    },
    name => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 255 
    },
    tel => { 
        data_type => "VARCHAR",
        default_value => "",
        is_nullable => 0,
        size => 16 
    },
    address => { 
        data_type => "VARCHAR",
        default_value => "",
        is_nullable => 0,
        size => 255 
    },
    building => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 255 
    },
    latitude => {
#        data_type => "DECIMAL",
        data_type => "DOUBLE",
        default_value => "0.000000",
        is_nullable => 0,
#        size => 10,
    },
    longitude => {
#        data_type => "DECIMAL",
        data_type => "DOUBLE",
        default_value => "0.000000",
        is_nullable => 0,
#        size => 10,
    },
    panorama => {
        data_type => "TEXT",
        default_value => undef,
        is_nullable => 0,
        size => 65535,
    },
    how_to_get_there => {
        data_type => "TEXT",
        default_value => undef,
        is_nullable => 1,
        size => 65535,
    },
    open_hours_memo => {
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
        default_value => undef,
        is_nullable => 1,
        set_on_create => 1,
        size => 19,
        timezone => 'Asia/Tokyo',
    },
    modified_at => {
        data_type => "DATETIME",
        default_value => undef,
        is_nullable => 1,
        set_on_update => 1,
        size => 19,
        timezone => 'Asia/Tokyo',
    },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    'openhours', 
    'GourmetSpot::Schema::Result::OpenHours',
    'restrant_id'
);
__PACKAGE__->has_many(
    'reviews',
    'GourmetSpot::Schema::Result::Review',
    'restrant_id'
);
__PACKAGE__->has_many(
    'map_restrant_tag',
    'GourmetSpot::Schema::Result::TagReview',
    'restrant_id'
);
__PACKAGE__->many_to_many(
    'tags',
    'map_restrant_tag',
    'tag'
);

1;
