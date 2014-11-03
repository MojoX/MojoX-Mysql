package MojoX::Mysql::Util;
use Mojo::Base -base;
use Mojo::Util qw(dumper);

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


1;
