package GourmetClub::Schema::Member;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("member");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "nickname",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "mail",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 128 },
  "password",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 40 },
  "caller_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-19 12:43:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HzV32lDwm05fchaoMVxN+w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
