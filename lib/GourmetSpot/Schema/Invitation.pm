package GourmetSpot::Schema::Invitation;

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
  { data_type => "CHAR", default_value => "", is_nullable => 0, size => 27 },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "member_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "joined_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-04-07 09:43:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QNSUHxKQaD8+P/nB23f4sw

__PACKAGE__->load_components(qw(InflateColumn::DateTime));
__PACKAGE__->add_columns(
    created_at => {
        data_type => 'datetime',
        extra => {timezone => 'Asia/Tokyo'},
    },
    joined_at => {
        data_type => 'datetime',
        extra => {timezone => 'Asia/Tokyo'},
    },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
