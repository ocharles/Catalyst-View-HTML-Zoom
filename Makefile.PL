use strict;
use warnings;
use inc::Module::Install 0.91;

if ($Module::Install::AUTHOR) {
    require Module::Install::AuthorRequires;
    require Module::Install::AuthorTests;
}

name 'Catalyst-View-HTML-Zoom';
all_from 'lib/Catalyst/View/HTML/Zoom.pm';

requires 'Catalyst::Runtime' => '5.80013';
requires 'Moose';
requires 'namespace::autoclean';
build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';
author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Catalyst/View/HTML/Zoom.pm > README")
        and die;
}

WriteAll();
