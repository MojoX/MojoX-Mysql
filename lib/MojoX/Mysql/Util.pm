package MojoX::Mysql::Util;
use Mojo::Base -base;
use Mojo::Util qw(dumper);
use Mojo::Collection 'c';

sub quote {
	my ($self,$str,$default) = @_;
	$default ||= 'DEFAULT';
	if($str){
		$str =~ s/['\\]/\\$&/gmo;
		return qq{'$str'};
	}
	else{
		return $default;
	}
}

sub id {
	my ($self) = @_;
	my @keys = sort {$a <=> $b} grep($_ ne '_default',keys %{$self->{'config'}});
	return c(@keys);
}

1;
