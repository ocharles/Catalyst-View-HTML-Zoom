package TestApp::View::HTML::Root;
use Moose;
use Method::Signatures::Simple;

method main ($stash) {
    $_->select("#name")->replace_content($stash->{name});
}

1;
