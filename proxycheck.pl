#!/usr/bin/perl

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

if (HTTP::ProxyCheck->check(proxy=>"$proxy", url => "$url", answer => "header")) {
	print "$proxy returns: " . HTTP::ProxyCheck->get_answer . "\n";
}
else {
	print "Error (" . HTTP::ProxyCheck->get_reason . ")\n";
}

print <<"OUTRO";

ProxyCheck done.

OUTRO
