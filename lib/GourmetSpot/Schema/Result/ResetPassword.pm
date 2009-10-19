package GourmetSpot::Schema::Result::ResetPassword;

use strict;
use warnings;

use base 'GourmetSpot::Schema::Result';

__PACKAGE__->load_components(qw(InflateColumn::DateTime Core));
__PACKAGE__->table("reset_password");
__PACKAGE__->add_columns(
    id => { 
        data_type => "INT", 
        default_value => undef, 
        is_nullable => 0, 
        is_auto_increment => 1,
        size => 11,
    },
    member_id => { 
        data_type => "INT", 
        default_value => 0, 
        is_nullable => 0, 
        size => 11 
    },
    nonce => { 
        data_type => "CHAR", 
        default_value => "", 
        is_nullable => 0, 
        size => 27 
    },
    expires_at => {
        data_type => "DATETIME",
        timezone => 'Asia/Tokyo',
        default_value => undef,
        is_nullable => 1,
        size => 19,
    },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( 
    'member', 
    'GourmetSpot::Schema::Result::Member',
    'member_id' 
);

1;
