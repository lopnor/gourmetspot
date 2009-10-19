package GourmetSpot::Schema::Result;
use strict;
use warnings;

use base 'DBIx::Class';

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->extra->{mysql_table_type} = 'INNODB';
    $sqlt_table->extra->{mysql_charset} = 'utf8';
}

1;
