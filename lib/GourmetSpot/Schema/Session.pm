package GourmetSpot::Schema::Session;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("session");
__PACKAGE__->add_columns(
  "id",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 72 },
  "session_data",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "expires",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-02-11 21:57:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yj6TgTuo6FO7D3FUM1cyKA


# You can replace this text with custom content, and it will be preserved on regeneration
1;