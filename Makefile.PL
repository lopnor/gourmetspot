# IMPORTANT: if you delete this file your app will not work as
# expected.  you have been warned
use inc::Module::Install;

name 'GourmetSpot';
all_from 'lib/GourmetSpot.pm';

requires 'Catalyst::Runtime' => '5.7015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::DBIC';
requires 'Catalyst::Plugin::FillInForm';
requires 'Catalyst::Plugin::FormValidator::Simple';
requires 'Catalyst::Plugin::FormValidator::Simple::Auto';
requires 'Catalyst::Plugin::Unicode';

requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::View::JSON';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema';
requires 'DBIx::Class::InflateColumn::DateTime';
requires 'WebService::Simple';
requires 'Catalyst::View::Email::Template';
requires 'TheSchwartz::Worker';
requires 'Class::Data::Inheritable';
requires 'YAML';
requires 'DateTime';
requires 'Digest::SHA1';
requires 'Email::MIME';
requires 'Email::MIME::Modifier';
requires 'Email::Send';
requires 'Module::Pluggable';
requires 'Path::Class';

requires 'parent';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

build_requires 'Test::WWW::Mechanize::Catalyst' => '0.500';

install_script glob('script/*.pl');
auto_install;
WriteAll;
