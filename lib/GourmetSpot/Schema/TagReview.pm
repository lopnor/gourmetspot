package GourmetSpot::Schema::TagReview;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tag_review");
__PACKAGE__->add_columns(
  "tag_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "review_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("tag_id", "review_id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-03-03 14:06:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oZf40wMYs+72Ws/OD+AuJg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
