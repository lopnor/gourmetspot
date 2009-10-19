package GourmetSpot::Schema::Invitation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(InflateColumn::DateTime TimeStamp Core));
__PACKAGE__->table("invitation");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_nullable => 0, 
        size => 11 
    },
    caller_id => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
    mail => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 128 
    },
    nonce => {
        data_type => "CHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 27 
    },
    created_at => { 
        data_type => "DATETIME",
        default_value => undef,
        is_nullable => 1,
        size => 19,
        timezone => 'Asia/Tokyo',
        set_on_create => 1,
    },
    member_id => { 
        data_type => "INT", 
        default_value => undef, 
        is_nullable => 1, 
        size => 11 
    },
    joined_at => {
        data_type => "DATETIME",
        default_value => undef,
        is_nullable => 1,
        size => 19,
        timezone => 'Asia/Tokyo',
    },
);

__PACKAGE__->set_primary_key("id");

1;
