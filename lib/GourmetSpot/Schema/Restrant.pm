package GourmetSpot::Schema::Restrant;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("restrant");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "name",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "tel",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 16 },
  "address",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "building",
  { data_type => "VARCHAR", default_value => "", is_nullable => 0, size => 255 },
  "latitude",
  {
    data_type => "DECIMAL",
    default_value => "0.000000",
    is_nullable => 0,
    size => 10,
  },
  "longitude",
  {
    data_type => "DECIMAL",
    default_value => "0.000000",
    is_nullable => 0,
    size => 10,
  },
  "panorama",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "how_to_get_there",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "open_hours_memo",
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


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-04-07 22:49:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZNCSvJSdgEk4pygmGoN9VQ

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

__PACKAGE__->has_many('openhours' => 'GourmetSpot::Schema::OpenHours' => 'restrant_id');
__PACKAGE__->has_many('reviews' => 'GourmetSpot::Schema::Review' => 'restrant_id');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
