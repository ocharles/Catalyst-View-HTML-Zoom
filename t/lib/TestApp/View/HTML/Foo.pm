package TestApp::View::HTML::Foo;
use Moose;
use namespace::autoclean;

sub bar {
    my ($self, $stash) = @_;
    $_->select('#name')->replace_content($stash->{name});
}

__PACKAGE__->meta->make_immutable;
