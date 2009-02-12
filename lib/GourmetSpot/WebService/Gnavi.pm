package GourmetSpot::WebService::Gnavi;

use strict;
use warnings;

use base 'WebService::Simple';

__PACKAGE__->config(
    base_url => 'http://api.gnavi.co.jp/ver1/RestSearchAPI/',
    response_parser => 'XML::LibXML',
);

sub search {
    my ( $self, $arg ) = @_;
    my $res = $self->get({freeword => $arg});
    return unless $res->is_success;
    warn $res->content;
    my $doc = $res->parse_response;
    my @rest = $doc->documentElement->findnodes('//rest');
    my $ret;
    for my $rest (@rest) {
        my $hash = {};
        for my $attr (qw(name address tel url)) {
            $hash->{$attr} = $rest->getElementsByTagName($attr)->shift->textContent;
        }
        push @{$ret}, $hash;
    }
    return $ret;
}

1;
