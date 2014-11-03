use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'MojoX::Mysql',
  VERSION_FROM => 'lib/MojoX/Mysql.pm',
  AUTHOR       => 'Kostya Ten <kostya@yandex.ru>',
  PREREQ_PM    => {'Mojolicious' => '5.57', 'DBD::mysql' => '4.028', 'DBI' => '1.631'},
  test         => {TESTS => 't/*.t'}
);
