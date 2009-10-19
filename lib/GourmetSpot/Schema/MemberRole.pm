package GourmetSpot::Schema::MemberRole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("member_role");
__PACKAGE__->add_columns(
  member_id => { 
      data_type => "INT", 
      default_value => 0, 
      is_nullable => 0, 
      size => 11 
  },
  role_id => { 
      data_type => "INT", 
      default_value => 0, 
      is_nullable => 0,
      size => 11 
  },
);
__PACKAGE__->set_primary_key("member_id", "role_id");
__PACKAGE__->belongs_to( member => 'GourmetSpot::Schema::Member', 'member_id' );
__PACKAGE__->belongs_to( role => 'GourmetSpot::Schema::Role', 'role_id' );

1;
