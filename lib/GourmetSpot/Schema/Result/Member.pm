package GourmetSpot::Schema::Result::Member;

use strict;
use warnings;

use base 'GourmetSpot::Schema::Result';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("member");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_nullable => 0, 
        is_auto_increment => 1,
        size => 11 
    },
    nickname => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 32 
    },
    mail => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 128 
    },
    password => { 
        data_type => "CHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 27 
    },
    caller_id => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(map_member_role => 'GourmetSpot::Schema::Result::MemberRole' => 'member_id');
__PACKAGE__->many_to_many(roles => 'map_member_role' => 'role');
__PACKAGE__->has_many(reviews => 'GourmetSpot::Schema::Result::Review' => 'created_by');

1;
