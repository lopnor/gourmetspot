package GourmetSpot;

use strict;
use warnings;
use 5.008001;

use YAML;

use Catalyst::Runtime '5.80';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
                ConfigLoader
                Static::Simple
                
                Authentication
                Authorization::Roles

                Session
                Session::State::Cookie
                Session::Store::DBIC

                FillInForm

                FormValidator::Simple

                +GourmetSpot::Util::ProfileLoader
                FormValidator::Simple::Auto

                MobileAgent

                Unicode
                /;

our $VERSION = '0.01';

# Configure the application. 
#
# Note that settings in gourmetspot.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

$YAML::Syck::ImplicitUnicode = 1;

__PACKAGE__->config( 
    name => 'GourmetSpot',
    'Plugin::ConfigLoader' => {
        driver => {
            'General' => { '-UTF8' => 1 }
        }
    }
);

# Start the application
__PACKAGE__->setup();

=head1 NAME

GourmetSpot - Catalyst based application

=head1 SYNOPSIS

    script/gourmetspot_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<GourmetSpot::Controller::Root>, L<Catalyst>

=head1 AUTHOR

danjou

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
