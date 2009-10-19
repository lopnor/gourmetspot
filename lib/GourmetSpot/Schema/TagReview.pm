package GourmetSpot::Schema::TagReview;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tag_review");
__PACKAGE__->add_columns(
    tag_id => { 
        data_type => "INT",
        default_value => 0,
        is_nullable => 0,
        size => 11 },

    review_id => { 
        data_type => "INT",
        default_value => 0,
        is_nullable => 0,
        size => 11 
    },
    restrant_id => { 
        data_type => "INT",
        default_value => 0,
        is_nullable => 0,
        size => 11 
    },
);
__PACKAGE__->set_primary_key("tag_id", "review_id");

__PACKAGE__->belongs_to( tag => 'GourmetSpot::Schema::Tag', 'tag_id');
__PACKAGE__->belongs_to( review => 'GourmetSpot::Schema::Review', 'review_id');
__PACKAGE__->belongs_to( restrant => 'GourmetSpot::Schema::Restrant', 'restrant_id');

1;
