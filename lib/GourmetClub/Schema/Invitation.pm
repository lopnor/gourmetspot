package GourmetClub::Schema::Invitation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("invitation");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "caller_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "mail",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 128 },
  "nonce",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 40 },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-19 12:43:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3NiCFSxTw6wNSgjk3SC9zw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
