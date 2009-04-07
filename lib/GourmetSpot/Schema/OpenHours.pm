package GourmetSpot::Schema::OpenHours;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("open_hours");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "restrant_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "day_of_week",
  { data_type => "SET", default_value => undef, is_nullable => 1, size => 27 },
  "holiday",
  { data_type => "ENUM", default_value => "false", is_nullable => 0, size => 6 },
  "pre_holiday",
  { data_type => "ENUM", default_value => "false", is_nullable => 0, size => 6 },
  "opens_at",
  { data_type => "TIME", default_value => undef, is_nullable => 1, size => 8 },
  "closes_at",
  { data_type => "TIME", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-04-07 09:43:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0giAOI0jR1VKQK+xFldFFw

__PACKAGE__->inflate_column('day_of_week', {
        inflate => sub { +{ map {($_ => 1)} split( ',', $_[0] ) } },
        deflate => sub { join( ',', @{ $_[0] } ) },
    });

# You can replace this text with custom content, and it will be preserved on regeneration
1;
