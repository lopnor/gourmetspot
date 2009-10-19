package GourmetSpot::Schema::Result::Role;

use strict;
use warnings;

use base 'GourmetSpot::Schema::Result';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_nullable => 0, 
        is_auto_increment => 1,
        size => 11,
    },
    role => { 
        data_type => "VARCHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 32 
    },
);
__PACKAGE__->set_primary_key("id");

1;
