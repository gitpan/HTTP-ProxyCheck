package HTTP::ProxyCheck;


#====================================================================#
# HTTP::ProxyCheck - Checks HTTP proxy servers.                      #
#====================================================================#


use strict;
use base qw(Class::Default);

use Validate::Net;
use IO::Socket;

# Globals
use vars qw($VERSION $answer $errstr $reason);

BEGIN {
	$VERSION = 1.0;
	$answer = '';
	$errstr = '';
	$reason = '';
}


#====================================================================#
# Constructor                                                        #
#====================================================================#

sub new {
	my $class = shift;

	my $self = {};
	bless $self,$class;

	return $self;
}


#====================================================================#
# Checking                                                           #
#====================================================================#

sub check {
	my $self = shift->_self;

	# initialize %args with answer => "header" (default) and @_
	my %args = (answer => "header", @_);
	my $return;
	my $dochost;
	
	$reason = '';

	# check wether proxy address is specified
	if (!$args{proxy}) {
		return $self->_set_reason("Proxy address: None specified");
	}
	# check proxy address
	else {
		$return = $self->check_address($args{proxy});
		if ($return != 1) {
			return $return;
		}
	}

	# check wether URL is specified
	if (!$args{url}) {
		return $self->_set_reason("URL: None specified");
	}

	# check URL
	if( $args{url} =~ m#^http://([^:/]+)(:\d+?/.*)?# ) {
		$dochost = $1;
	}
	else {
		return $self->_set_reason
		("URL: Doesn't comply with the pattern of a valid URL for ProxyCheck e.g. 'http://www.cpan.org/index.html'");
	}

	# check the provided $args{answer}
	if ($args{answer} !~ /^header|full$/) {
		$args{answer} = "header";
	}

	# do proxy check
	$self->_check_proxy(%args, dochost=>$dochost);

	if ($self->get_reason()) {
		return 0;
	}
	else {
		$return = 1;
	}

	return $return;
}

sub check_address {
	my $self = shift->_self;
	my $proxyaddress = shift;

	$reason = '';
	
	# Proxy address format
	if ($proxyaddress !~ /.*:\d{1,5}\b/) {
		return $self->_set_reason("Proxy address: Doesn't comply with the pattern 'host:port' e.g. 'proxy:8080'");
	}

	$proxyaddress =~ m/(.*):(\d{1,5})\b/;

	my $proxyhost = $1;

	my $proxyport = $2;

	if (!(Validate::Net->host($proxyhost) && Validate::Net->port($proxyport))) {
		return $self->_set_reason("Proxy address: ".Validate::Net->reason());
	}

	# Else: OK
	return 1;
}


#====================================================================#
# Private _check_proxy() Method                                      #
#====================================================================#

sub _check_proxy {
	my $self = shift->_self;
	
	# _checkProxy() needs the following arguments:
	# %args = ( proxy => "$proxy", url => "$url", 
	#	dochost => "$dochost"  [, answer => "header" | "full"] )

	my %args = @_;

	$reason = '';

  	my ($buff, $tmp, $line, $EOL);

  	$EOL = "\015\012";

  	my $socket=IO::Socket::INET->new(
  		PeerAddr => $args{proxy},
  		Proto => "tcp",
  		Timeout => 5,
  		Type => SOCK_STREAM);

	if ($@) {
		return $self->_set_reason("ProxyCheck: $@");
	} 

  	$tmp = <<"REQUEST";
GET $args{url} HTTP/1.0
Referer: None
User-Agent: HTTP::ProxyCheck/0.1
Host: $args{dochost}
Pragma: no-cache
Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*
Accept-Encoding: gzip
Accept-Language: en
Accept-Charset: iso-8859-1

REQUEST

  	$tmp =~ s/\n/\015\012/g;

  	select($socket); $| = 1 ; select(STDOUT);
  	print $socket $tmp;

  	while (defined($line = <$socket>)) {
     		$line =~ s#<.?>##g;
     		$buff .= "\n$line";
  	}
 
	if ($args{answer} eq "header") { 
  		$buff =~ m#.+\n?#;
  		$buff = $&;
		$buff =~ s/\n//g;
	}

	close ($socket);

	$self->_set_answer($buff);	

  	return 1;
}


#====================================================================#
# Public message handling methods                                    #
#====================================================================#

sub get_answer {
	return $answer;
}

sub get_reason {
	return $reason;
}


#====================================================================#
# Private message handling methods                                   #
#====================================================================#

sub _set_answer {
	$answer = $_[1];
	undef;
}

sub _set_reason {
	$reason = $_[1];
	return 0;
}


1;


__END__

=pod

=head1 NAME

HTTP::ProxyCheck - Checks HTTP proxy servers.

=head1 SYNOPSIS

=head2 CHECK HTTP PROXY

  use HTTP::ProxyCheck;

  # $OUTPUT_AUTOFLUSH
  $| = 1;

  my $proxycheck = new HTTP::ProxyCheck();
  my $proxy = "10.0.0.1:8080";
  my $url = "http://www.perl.org/index.shtml";

  print "Trying to connect to $proxy and retrieve $url\n";

  if ($proxycheck->check(proxy=> "$proxy",url=> "$url",answer=>"header")) {
  	print "$proxy returns: " . $proxycheck->get_answer() . "\n";
  }
  else {
  	print "Error (" . $proxycheck->get_reason() . ")\n";
  }

=head2 CHECK PROXY ADDRESS

  use HTTP::ProxyCheck;

  my $proxycheck = new HTTP::ProxyCheck();
  my $proxy = "10.0.0.1:8080";

  print "Checking proxy address $proxy\n";

  if ($proxycheck->check_address($proxy) {
  	print "$proxy is a valid proxy address\n";
  }
  else {
  	print "Error (" . $proxycheck->get_reason() . ")\n";
  }

=head1 DESCRIPTION

HTTP::ProxyCheck is a class to check HTTP proxy servers. It connects to given 
HTTP proxy servers and tries to retrieve a provided URL through them. You 
can also use HTTP::ProxyCheck to check wether the syntax of a proxy 
address may be valid without connecting to a server.

The return message from the proxy servers can be accessed through the 
C<get_answer> method.

Whenever a check fails, you can access the reason through the C<get_reason> 
method.

=head1 METHODS

=head2 check( proxy => $proxy, url => $url, answer => $type )

The C<check> method is used to check a HTTP proxy server. The C<check> method
includes a test to check the syntax of the provided proxy server address 
(C<check_address>) and URL. You can specify wether you want to get only the 
header ($type = "header") or the full page ($type = "full") as return value 
from the method. This specification is optionally. The default answer is 
$type = "header".

=head2 check_address( $proxy )

The C<check_address> method is used to check for a valid proxy server address. When 
you use C<check> the proxy address is checked with this method automatically.

=head2 get_answer( )

Through the C<get_answer> method the return message from the proxy servers can be 
accessed.

=head2 get_reason( )

When a proxy check fails, the reason can be accessed through the C<get_reason> 
method.

=head1 BUGS

Unknown

=head1 SUPPORT

Contact the author

=head1 AUTHOR

        Thomas Weibel
        cpan@beeblebrox.net
        http://beeblebrox.net/

=head1 COPYRIGHT

Copyright (c) 2003 Thomas Weibel. All rights reserved.

This library is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
