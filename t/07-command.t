use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(dumper);
use FindBin;
use lib "$FindBin::Bin/../lib/";
use lib "$FindBin::Bin";
use MojoX::Mysql;
use Mojolicious::Command::sql;

plan skip_all => 'set MOJO_TEST_TRAVIS to enable this test' unless $ENV{'MOJO_TEST_TRAVIS'};

my %config = (
	user=>'root',
	password=>undef,
	server=>[
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master', migration=>'migration::default', fake=>'migration::fake'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
	],
);
$config{'user'} = 'root' if(defined $ENV{'MOJO_TEST_TRAVIS'} && $ENV{'MOJO_TEST_TRAVIS'} == 1);

plugin 'Mysql' => \%config;
my $t = Test::Mojo->new;
Mojolicious::Command::sql->new(app=>$t->app)->run('delete')->run('create')->run('update')->run('fake');

get '/' => sub {
	my $self = shift;
	$self->app->mysql->query('SELECT * FROM `test1`');
	$self->app->mysql->query('SELECT * FROM `test2`');
	$self->render(json=>{});
	return;
};

$t->get_ok('/');
$t->status_is(200);

my $result = $t->app->mysql->query('SELECT * FROM `test1`');
ok($result->[0]->{'text'} eq 'Тест', 'ok fake');

done_testing();
