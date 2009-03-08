package GourmetSpot::Util;
use strict;
use warnings;

use base qw(Class::Data::Inheritable);
use FindBin;
use Hash::Merge::Simple ();
use YAML;
use Path::Class qw(file dir);
use Digest::SHA1 qw(sha1_base64);
use Data::Visitor::Callback;

__PACKAGE__->mk_classdata('config');

sub load_config {
    my ($class) = @_;
    my $basedir = $ENV{CATALYST_CONFIG} ? 
        dir($ENV{CATALYST_CONFIG}) : file($FindBin::Bin)->parent;
    my $config = { home => $basedir->stringify };
    for my $cfg ( qw/gourmetspot.yml gourmetspot_local.yml/ ) {
        my $c = eval {
            YAML::LoadFile( $basedir->file($cfg) );
        } or next;

        $config = Hash::Merge::Simple::merge($config, $c);
    }
    my $v = Data::Visitor::Callback->new(
        plain_value => sub {
            return unless defined $_;
            $class->config_substitutions( $_ );
        }
    );
    $v->visit( $config );
    $class->config($config);
    return $config;
}

sub config_substitutions {
    my $class    = shift;
    my $subs = {};
    $subs->{ HOME }    = sub { shift->path_to( '' ); };
    $subs->{ path_to } = sub { shift->path_to( @_ ); };
    $subs->{ literal } = sub { return $_[ 1 ]; };
    my $subsre = join( '|', keys %$subs );

    for ( @_ ) {
        s{__($subsre)(?:\((.+?)\))?__}{ $subs->{ $1 }->( $class, $2 ? split( /,/, $2 ) : () ) }eg;
    }
}

sub path_to {
    my ( $class, @path ) = @_;
    my $basedir = $ENV{CATALYST_CONFIG} ? 
        dir($ENV{CATALYST_CONFIG}) : file($FindBin::Bin)->parent;
    my $path = Path::Class::Dir->new( $basedir, @path );
    if ( -d $path ) { return $path }
    else { return Path::Class::File->new( $basedir, @path ) }
}

sub compute_password {
    my ( $class, $raw, $c ) = @_;
    my $config = $c ? $c->config : $class->load_config;
    my $credential = $config->{'Plugin::Authentication'}
                                ->{realms}
                                ->{members}
                                ->{credential};
    return sha1_base64(
        ($credential->{password_pre_salt} || '')
        . $raw
        . ($credential->{password_post_salt} || '')
    );
}

1;
