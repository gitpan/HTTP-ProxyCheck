package HTTP::ProxyCheck;


#====================================================================#
# HTTP::ProxyCheck - Checks HTTP proxy servers.                      #
#====================================================================#


use strict;
use base qw(Class::Default);

use Validate::Net;
use IO::Socket;

# Globals
use vars qw($VERSION $errstr $reason $answer %DEFAULT);

BEGIN {
	$VERSION = 0.1;
	$errstr = '';
	$reason = '';
}

# get version
sub getVersion {
	return $VERSION;
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
	my %args = @_;
	my $return;
	my $dochost;
	
	$reason = '';

	# check wether proxy address is specified
	if (!$args{proxy}) {
		return $self->setReason("Proxy address: None specified");
	}
	# check proxy address
	else {
		$return = $self->check_proxyaddress($args{proxy});
		if ($return != 1) {
			return $return;
		}
	}

	# check wether URL is specified
	if (!$args{url}) {
		return $self->setReason("URL: None specified");
	}

	# check URL
	if( $args{url} =~ m#^http://([^:/]+)(:\d+?/.*)?# ) {
		$dochost = $1;
	}
	else {
		return $self->setReason
		("URL: Doesn't comply with the pattern of a valid URL for ProxyCheck e.g. 'http://www.cpan.org/index.html'");
	}

	# do proxy check
	$self->check_proxy(%args, dochost=>$dochost);

	if ($self->getReason()) {
		return 0;
	}
	else {
		$return = 1;
	}

	return $return;
}

sub check_proxyaddress {
	my $self = shift->_self;
	my $proxyaddress = shift;

	$reason = '';
	
	# Proxy address format
	if ($proxyaddress !~ /.*:\d{1,5}\b/) {
		return $self->setReason("Proxy address: Doesn't comply with the pattern 'host:port' e.g. 'proxy:8080'");
	}

	$proxyaddress =~ m/(.*):(\d{1,5})\b/;

	my $proxyhost = $1;

	my $proxyport = $2;

	if (!(Validate::Net->host($proxyhost) && Validate::Net->port($proxyport))) {
		return $self->setReason("Proxy address: ".Validate::Net->reason());
	}

	# Else: OK
	return 1;
}

sub check_proxy {
	my $self = shift->_self;
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
		return $self->setReason("ProxyCheck: $@");
	} 

  	$tmp = <<"REQUEST";
GET $args{url} HTTP/1.0
Referer: http://www.perl.org/
User-Agent: ProxyCheck/0.1
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
  
  	$buff =~ m#.+\n?#;
  	$buff = $&;
	$buff =~ s/\n//g;

	close ($socket);

	$self->setAnswer($buff);	

  	return 1;
}


#====================================================================#
# Message handling                                                   #
#====================================================================#

sub setAnswer {
	$answer = $_[1];
	undef;
}

sub setReason {
	$reason = $_[1];
	return 0;
}

sub getAnswer {
	return $answer;
}

sub getReason {
	return $reason;
}

1;


__END__

=pod

=head1 NAME

HTTP::ProxyCheck - Checks HTTP proxy servers.

=head1 SYNOPSIS

  use HTTP::ProxyCheck;

  # $OUTPUT_AUTOFLUSH
  $| = 1;

  my $proxy = "10.0.0.1:8080";
  my $url = "http://www.perl.org/index.shtml";

  print "Trying to connect to $proxy and retrieve $url\n";

  if (ProxyCheck->check(proxy=>"$proxy", url => "$url")) {
	  print "$proxy returns: ".ProxyCheck->getAnswer."\n";
  }
  else {
	  print "Error (".ProxyCheck->getReason.")\n";
  }

=head1 DESCRIPTION

HTTP::ProxyCheck is a class to check HTTP proxy servers. It connects to given 
HTTP proxy servers and tries to retrieve a provided URL through them.

The return message from the proxy servers can be accessed through the 
C<getAnswer> method.

Whenever a check fails, you can access the reason through the C<getReason> 
method.

=head1 METHODS

=head2 check( proxy => "$proxy", url => "$url" )

The C<check> method is used to check a HTTP proxy server. The C<check> method
includes a test to check the syntax of the provided proxy server address and
URL.

=head2 check_proxyaddress( $proxyaddress )

The C<check_proxyaddress> method is used to check for a valid proxy server 
address.

=head2 check_proxy( proxy => "$proxy", url => "$url", dochost => "$dochost" )

The C<check_proxy> method is used to check a HTTP proxy server. In contrast to
the C<check> method C<check_proxy> doesn't check the syntax of the provided 
proxy server address and URL. It also doesn't extract the document host from 
the specified URL.

=head1 BUGS

Unknown

=head1 SUPPORT

Contact the author

=head1 AUTHOR

        Thomas Weibel
        thomas@beeblebrox.net
        http://beeblebrox.net/

=head1 COPYRIGHT

Copyright (c) 2003 Thomas Weibel. All rights reserved.

This library is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
