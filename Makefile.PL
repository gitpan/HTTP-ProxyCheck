use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'HTTP::ProxyCheck',
    'VERSION_FROM'	=> 'lib/HTTP/ProxyCheck.pm',
    'PREREQ_PM'		=> {
            'Class::Default'	=> 0.2,
            'IO::Socket'	=> 0,
            'Validate::Net'	=> 0.3
    },
    ($] >= 5.005 ? (
            'ABSTRACT'		=> 'Checks HTTP proxy servers.',
            'AUTHOR'		=> 'Thomas Weibel (thomas@beeblebrox.net)'
    ) : ()),
);
