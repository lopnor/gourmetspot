package GourmetSpot::Schema::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "role",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-04-07 09:43:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cD7x4zK7exzad0851fTLJw

__PACKAGE__->has_many('map_member_role' => 'GourmetSpot::Schema::MemberRole' => 'role_id');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
