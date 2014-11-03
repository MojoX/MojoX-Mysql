package MojoX::Mysql;
use Mojo::Base -base;
use List::Util qw(shuffle);
use Time::HiRes qw(sleep gettimeofday);
use Mojo::Util qw(dumper);
use DBI;
use Carp qw(croak);

our $VERSION  = '0.01';

use MojoX::Mysql::DB;
use MojoX::Mysql::Result;

has [qw(async slave)];
has [qw(id)] => '_default';
has 'db'=> sub {
	my $self = shift;
	return MojoX::Mysql::DB->new(config=>$self->{'config'});
};

has 'result'=> sub {
	my $self = shift;
	return MojoX::Mysql::Result->new();
};

sub new {
	my $class = shift;
	my %args  = @_;

	my %config = ();
	if(exists $args{'server'}){
		for my $server (@{$args{'server'}}){

			# Add the global login
			$server->{'user'} = $args{'user'} if(!exists $server->{'user'} && exists $args{'user'});

			# Add the global password
			$server->{'password'} = $args{'password'} if(!exists $server->{'password'} && exists $args{'password'});

			# Add the global write_timeout
			$server->{'write_timeout'} = $args{'write_timeout'} if(!exists $server->{'write_timeout'} && exists $args{'write_timeout'});

			# Add the global read_timeout
			$server->{'read_timeout'} = $args{'read_timeout'} if(!exists $server->{'read_timeout'} && exists $args{'read_timeout'});

			$server->{'id'} = '_default'    if(!exists $server->{'id'});
			$server->{'type'} = 'slave'     if(!exists $server->{'type'});
			$server->{'weight'} = 1         if(!exists $server->{'weight'});
			$server->{'write_timeout'} = 60 if(!exists $server->{'write_timeout'});
			$server->{'read_timeout'}  = 60 if(!exists $server->{'read_timeout'});

			my $id = $server->{'id'};
			if($server->{'type'} eq 'slave'){
				for(1..$server->{'weight'}){
					push(@{$config{$id}}, $server);
				}
			}
			else{
				push(@{$config{$id}}, $server);
			}
		}
	}

	while(my($id,$data) = each(%config)){
		my @master = grep($_->{'type'} eq 'master', @{$data});
		my @slave = grep($_->{'type'} eq 'slave', @{$data});
		@slave = shuffle @slave;
		my $master = {};
		$master = $master[0] if(@master);
		$config{$id} = {master=>$master, slave=>\@slave};
	}
	return $class->SUPER::new(config=>\%config);
}

sub do {
	my ($self,$sql) = (shift,shift);
	my $dbh = $self->db->id($self->id)->connect_master;
	my $counter = $dbh->do($sql,undef,@_) or die $dbh->errstr;
	my $insertid = int $dbh->{'mysql_insertid'};
	return wantarray ? ($insertid,$counter) : $insertid;
}

sub query {
	my ($self, $query) = (shift, shift);
	my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

	my $dbh;
	if(defined $self->async && defined $self->slave){
		$dbh = $self->db->id($self->id)->connect_slave;
		die 'No connect server' if(ref $dbh ne 'DBI::db');
		$dbh = $dbh->clone;
	}
	elsif(defined $self->async){
		$dbh = $self->db->id($self->id)->connect_master;
		if(ref $dbh ne 'DBI::db'){
			$dbh = $self->db->id($self->id)->connect_slave;
		}
		die 'No connect server' if(ref $dbh ne 'DBI::db');
		$dbh = $dbh->clone;
	}
	elsif(defined $self->slave){
		$dbh = $self->db->id($self->id)->connect_slave;
		die 'No connect server' if(ref $dbh ne 'DBI::db');
	}
	else{
		$dbh = $self->db->id($self->id)->connect_master;
		if(ref $dbh ne 'DBI::db'){
			$dbh = $self->db->id($self->id)->connect_slave;
		}
		die 'No connect server' if(ref $dbh ne 'DBI::db');
	}

	if(defined $self->async){
		my $sth = $dbh->prepare($query, {async=>1}) or croak $dbh->errstr;
		$sth->execute(@_) or croak $dbh->errstr;
		return ($sth,$dbh);
	}
	else{
		my $sth = $dbh->prepare($query) or croak $dbh->errstr;
		my $counter = $sth->execute(@_) or croak $dbh->errstr;
		my $collection = $self->result->collection($sth,$cb);
		return wantarray ? ($collection,$counter,$sth,$dbh) : $collection;
	}
}

1;
