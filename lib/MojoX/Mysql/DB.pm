package MojoX::Mysql::DB;
use Mojo::Base -base;
use Mojo::Util qw(dumper);
use Carp qw(croak);

has [qw(id)] => '_default';

sub DESTROY {
	my $self = shift;
	$self->rollback;
	$self->disconnect;
	$self->flush;
}

# Master connect DB
sub connect_master {
	my $self = shift;
	my $id   = $self->id;
	$self->flush;

	my $config = {};
	if(exists $self->{'config'}->{$id}->{'master'}){
		$config = $self->{'config'}->{$id}->{'master'};
	}
	else{
		croak 'Not found id server';
	}

	if(defined $config && ref($config) eq 'HASH' && %{$config}){
		if(ref($self->{'dbh'}{'master'}{$id}) eq 'DBI::db'){
			my $dbh = $self->{'dbh'}{'master'}{$id};
			return $dbh if($dbh->ping);
		}

		my $dbh = DBI->connect("DBI:mysql:".$config->{'dsn'}, $config->{'user'}, $config->{'password'}, {
			AutoCommit=>0,
			RaiseError=>0,
			PrintError=>0,
			mysql_enable_utf8=>1,
			mysql_auto_reconnect=>1,
			mysql_write_timeout=>$config->{'write_timeout'},
			mysql_read_timeout=>$config->{'read_timeout'},
		});

		if($DBI::errstr){
			$self->{'dbh'}{'master'}{$id} = undef;
			return;
		}
		else{
			$self->{'dbh'}{'master'}{$id} = $dbh;
			$dbh->{'RaiseError'} = 1;
			return $dbh;
		}
	}
	return;
}

# Slave connect DB
sub connect_slave {
	my $self = shift;
	my $id   = $self->id;
	$self->flush;

	my $config = {};
	if(exists $self->{'config'}{$id}->{'slave'}){
		$config = $self->{'config'}->{$id}->{'slave'};
	}
	else{
		croak 'Not found id server';
	}

	if(defined $config && ref($config) eq 'ARRAY' && @{$config}){
		if(ref($self->{'dbh'}{'slave'}{$id}) eq 'DBI::db'){
			my $dbh = $self->{'dbh'}{'slave'}{$id};
			return $dbh if($dbh->ping);
		}

		for my $conf (@{$config}){

			my $dbh = DBI->connect("DBI:mysql:".$conf->{'dsn'}, $conf->{'user'}, $conf->{'password'}, {
				AutoCommit=>0,
				RaiseError=>0,
				PrintError=>0,
				mysql_enable_utf8=>1,
				mysql_auto_reconnect=>1,
				mysql_write_timeout=>$conf->{'write_timeout'},
				mysql_read_timeout=>$conf->{'read_timeout'},
			});

			if($DBI::errstr){
				$self->{'dbh'}{'slave'}{$id} = undef;
				next;
			}
			else{
				$self->{'dbh'}{'slave'}{$id} = $dbh;
				$dbh->{'RaiseError'} = 1;
				return $dbh;
			}
		}
	}
	return;
}

sub commit {
	my ($self) = @_;
	while(my($id,$types) = each %{$self->{'dbh'}}){
		if(ref $types eq 'HASH'){
			for my $type (keys %{$types}){
				my $dbh = $self->{'dbh'}->{$id}->{$type};
				$dbh->commit if(ref $dbh eq 'DBI::db');
				warn "commit:$id,$type" if(defined $ENV{'MOJO_MYSQL_DEBUG'});
			}
		}
	}
}

sub rollback {
	my ($self) = @_;
	while(my($id,$types) = each %{$self->{'dbh'}}){
		if(ref $types eq 'HASH'){
			for my $type (keys %{$types}){
				my $dbh = $self->{'dbh'}->{$id}->{$type};
				$dbh->rollback if(ref $dbh eq 'DBI::db');
				warn "rollback:$id,$type" if(defined $ENV{'MOJO_MYSQL_DEBUG'});
			}
		}
	}
}

sub disconnect {
	my ($self) = @_;
	while(my($id,$types) = each %{$self->{'dbh'}}){
		if(ref $types eq 'HASH'){
			for my $type (keys %{$types}){
				my $dbh = $self->{'dbh'}->{$id}->{$type};
				$dbh->disconnect if(ref $dbh eq 'DBI::db');
				warn "disconnect:$id,$type" if(defined $ENV{'MOJO_MYSQL_DEBUG'});
				delete $self->{'dbh'};
			}
		}
	}
}

sub flush {
	my $self = shift;
	$self->id('_default');
}

1;
