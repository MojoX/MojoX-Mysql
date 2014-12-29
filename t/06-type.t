use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Util qw(dumper);
use FindBin;
use lib "$FindBin::Bin/../lib/";
use MojoX::Mysql;

plan skip_all => 'set TEST_ONLINE to enable this test' unless $ENV{TEST_ONLINE};

my %config = (
	user=>'root',
	password=>undef,
	server=>[
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>1, type=>'slave'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'master'},
		{dsn=>'database=test;host=localhost;port=3306;mysql_connect_timeout=5;', id=>2, type=>'slave'},
	]
);
$config{'user'} = 'travis' if(defined $ENV{'USER'} && $ENV{'USER'} eq 'travis');

my $mysql = MojoX::Mysql->new(%config);
$mysql->do('DROP TABLE IF EXISTS `test`;'); # Delete table

$mysql->do(q{
	CREATE TABLE IF NOT EXISTS `test` (
	  `id` int(11) NOT NULL AUTO_INCREMENT,
	  `datetime` datetime NOT NULL,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='test table' AUTO_INCREMENT=1;
});

my ($insertid,$counter) = $mysql->do('INSERT INTO `test` (`datetime`) VALUES("2001-01-01 00:00:00")');
ok($insertid == 1, 'insertid');

my $result = $mysql->query('SELECT `datetime` FROM `test` WHERE `id` = ? LIMIT 1', $insertid);
$result->each(sub{
	my $e = shift;
	ok($e->{'datetime'}->to_string eq 'Mon, 01 Jan 2001 00:00:00 GMT');
});

done_testing();
