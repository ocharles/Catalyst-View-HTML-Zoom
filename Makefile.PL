use inc::Module::Install;

name 'Catalyst-View-HTML-Zoom';
all_from 'lib/Catalyst/View/HTML/Zoom.pm';

build_requires 'Catalyst::Runtime';
build_requires 'Test::WWW::Mechanize::Catalyst';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
