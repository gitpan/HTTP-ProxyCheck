#!/usr/bin/perl -w

use strict;
use warnings;

use HTTP::ProxyCheck;

# $OUTPUT_AUTOFLUSH
$| = 1;

my $proxy = "10.0.0.1:8080";
my $url = "http://www.perl.org/index.shtml";

print <<"INTRO";

Performing ProxyCheck...

Trying to connect to $proxy and retrieve $url
INTRO


if (HTTP::ProxyCheck->check(proxy=>"$proxy", url => "$url")) {
	print "$proxy returns: ".HTTP::ProxyCheck->getAnswer;
}
else {
	print "Error (".HTTP::ProxyCheck->getReason.")";
}

print <<"OUTRO";


ProxyCheck done.

OUTRO
