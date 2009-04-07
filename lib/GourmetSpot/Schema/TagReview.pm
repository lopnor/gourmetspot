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


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-04-07 09:43:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5YLRkO18pykFYWu5iDrGHw

__PACKAGE__->belongs_to( tag => 'GourmetSpot::Schema::Tag', 'tag_id');
__PACKAGE__->belongs_to( review => 'GourmetSpot::Schema::Review', 'review_id');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
