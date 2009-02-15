package GourmetSpot::Schema::Review;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("review");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "restrant_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "budget",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 32 },
  "scene_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
  "comment",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "created_by",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "created_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
  "modified_at",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => 19,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-02-11 21:57:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MRZ+Xs5ry7GJfElFMVypbw

__PACKAGE__->load_components(qw(InflateColumn::DateTime));

__PACKAGE__->add_columns(
    created_at => {
        data_type => 'datetime',
        extra => {timezone => 'Asia/Tokyo'},
    },
    modified_at => {
        data_type => 'datetime',
        extra => {timezone => 'Asia/Tokyo'},
    },
);

__PACKAGE__->belongs_to('restrant' => 'GourmetSpot::Schema::Restrant' => 'restrant_id');
__PACKAGE__->belongs_to('member' => 'GourmetSpot::Schema::Member' => 'created_by');
__PACKAGE__->belongs_to('scene' => 'GourmetSpot::Schema::Scene' => 'scene_id');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
