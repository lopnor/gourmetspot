use strict;
use warnings;
use Test::More tests => 13;
use Test::MockObject;
use File::Spec::Functions;
use File::Temp;
use Path::Class qw(dir);
use YAML;
use Digest::SHA1 qw(sha1_base64);

BEGIN { use_ok qw(GourmetSpot::Util); }

{
    ok my $config = GourmetSpot::Util->load_config;
    isa_ok $config, 'HASH';
}

{
    my $dir = File::Temp->newdir;
    my $data = {
        config_file => '__path_to(gourmetspot.yml)__',
        home_dir => '__HOME__',
        riteral => '__literal(__HOME__)__',
        foo => 'bar',
    };
    my $expect = {
        home => $dir->dirname,
        home_dir => $dir->dirname,
        config_file => catfile($dir->dirname, "gourmetspot.yml"),
        riteral => '__HOME__',
        foo => 'bar',
    };
    YAML::DumpFile(catfile($dir->dirname, "gourmetspot.yml"),$data);
    local $ENV{CATALYST_CONFIG} = $dir->dirname;
    my $config = GourmetSpot::Util->load_config;
    is_deeply $config, $expect;
}
{
    my $dir = File::Temp->newdir;
    my $data = {
        home => $dir->dirname,
        foo => 'bar',
    };
    YAML::DumpFile(catfile($dir->dirname, "gourmetspot.yml"),$data);
    local $ENV{CATALYST_CONFIG} = $dir->dirname;
    my $config = GourmetSpot::Util->load_config;
    is_deeply $config, $data;
}
{
    my $dir = File::Temp->newdir;
    my $data = {
        home => $dir->dirname,
        foo => 'bar',
    };
    YAML::DumpFile(catfile($dir->dirname, "gourmetspot.yml"),$data);
    local $ENV{CATALYST_CONFIG} = $dir->dirname;
    my $config = GourmetSpot::Util->load_config;
    is_deeply $config, $data;
}

{
    my $pre = 'hoge';
    my $post = 'fuga';
    my $c = Test::MockObject->new;
    my $hash = {
        'Plugin::Authentication' => {realms => {members => {credential => 
                    {
                        password_pre_salt => $pre,
                        password_post_salt => $post,
                    }
                }}}
    };
    $c->mock( 'config' => sub { return $hash } );
    my $password = 'hogehoge';
    ok my $hashed = GourmetSpot::Util->compute_password($password, $c);
    is $hashed, sha1_base64($pre.$password.$post);
}
{
    my $pre = 'hoge';
    my $c = Test::MockObject->new;
    my $hash = {
        'Plugin::Authentication' => {realms => {members => {credential => 
                    {
                        password_pre_salt => $pre,
                    }
                }}}
    };
    $c->mock( 'config' => sub { return $hash } );
    my $password = 'hogehoge';
    ok my $hashed = GourmetSpot::Util->compute_password($password, $c);
    is $hashed, sha1_base64($pre.$password);
}
{
    my $post = 'fuga';
    my $c = Test::MockObject->new;
    my $hash = {
        'Plugin::Authentication' => {realms => {members => {credential => 
                    {
                        password_post_salt => $post,
                    }
                }}}
    };
    $c->mock( 'config' => sub { return $hash } );
    my $password = 'hogehoge';
    ok my $hashed = GourmetSpot::Util->compute_password($password, $c);
    is $hashed, sha1_base64($password,$post);
}
{
    my $password = 'hogehoge';
    ok my $hashed = GourmetSpot::Util->compute_password($password);
}
