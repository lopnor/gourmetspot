#!/usr/bin/perl
use strict;
use warnings;
use lib "lib";
use GourmetSpot::Schema;

my $schema = GourmetSpot::Schema->connect('dbi:mysql:gourmetspot','root');
for my $row ($schema->resultset('TagReview')->all) {
    $row->update( {restrant_id => $row->review->restrant_id} );
}
