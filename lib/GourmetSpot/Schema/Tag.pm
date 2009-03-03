package GourmetSpot::Schema::Tag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tag");
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
__PACKAGE__->add_unique_constraint("value", ["value"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-03-03 15:20:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WncyoJDHQNMGBmf4tMgqIQ

__PACKAGE__->has_many('map_review_tag' => 'GourmetSpot::Schema::TagReview' => 'tag_id');
__PACKAGE__->many_to_many('reviews' => 'map_review_tag' => 'review');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
