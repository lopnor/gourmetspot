package GourmetSpot::Util::ProfileLoader;
use strict;
use warnings;
use YAML;
use Encode;

sub setup {
    my $c = shift;

    my $config = $c->config->{validator};

    Catalyst::Exception->throw( message =>
          __PACKAGE__ . qq/: You need to load "Catalyst::Plugin::FormValidator::Simple"/ )
      unless $c->isa('Catalyst::Plugin::FormValidator::Simple');

    $c->log->warn( __PACKAGE__ . qq/: You must set validator profiles/ )
      unless $config->{profiles};

    if ( $config->{profiles} and ref $config->{profiles} ne 'HASH' ) {
        my $profiles = eval {
            no warnings 'once';
            local $YAML::UseAliases = 0;
            YAML::Load( Encode::decode( 'utf8', YAML::Dump( YAML::LoadFile( $config->{profiles} ) ) ) ); # XXX: remove yaml aliases
        };
        Catalyst::Exception->throw( message => __PACKAGE__ . qq/: $@/ ) if $@;

        $config->{profiles} = $profiles;
    }
    $c->NEXT::setup(@_);
}

1;
