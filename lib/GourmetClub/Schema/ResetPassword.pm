package GourmetClub::Schema::ResetPassword;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("reset_password");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "member_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "nonce",
  { data_type => "CHAR", default_value => "", is_nullable => 0, size => 27 },
  "expires_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-01-25 11:22:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zxKqRLopmG+Nxx1o315fbw

__PACKAGE__->load_components(qw(InflateColumn::DateTime));

__PACKAGE__->add_columns(
    expires_at => {
        data_type => 'datetime',
        extra => {timezone => 'Asia/Tokyo'},
    },
);

__PACKAGE__->belongs_to( member => 'GourmetClub::Schema::Member' => 'member_id' );

# You can replace this text with custom content, and it will be preserved on regeneration
1;
