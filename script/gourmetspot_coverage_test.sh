#!/bin/zsh

echo "
use strict;
use warnings;
use Test::More;

my @modules = qw(
" > t/00_allload.t

find lib -name "*.pm" | sed "s/lib\//   /;s/\.pm//;s/\//::/g" >> t/00_allload.t

echo "
);

plan tests => scalar (@modules) + 1;

use_ok('Catalyst::Test', 'GourmetSpot');
use_ok \$_ for @modules;
" >> t/00_allload.t

rm -rf cover_db
perl Makefile.PL
HARNESS_PERL_SWITCHES=-MDevel::Cover=+ignore,inc,-coverage,statement,branch,condition,path,subroutine make test
cover
rm -f t/00_allload.t
rm -rf cover_db_view
mv cover_db cover_db_view
open cover_db_view/coverage.html
