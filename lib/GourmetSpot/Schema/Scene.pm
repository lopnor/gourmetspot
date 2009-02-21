package GourmetSpot::Schema::Scene;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("scene");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "value",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "created_by",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-02-21 20:51:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aDysva0gdNWD2x7xW6yzDw

__PACKAGE__->load_components(qw(InflateColumn::DateTime));

__PACKAGE__->add_columns(
    created_at => {
        data_type => 'datetime',
        extra => {timezone => 'Asia/Tokyo'},
    },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;
