package TestApp::Controller::Foo;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub bar :Local {
    my ($self, $c) = @_;
    $c->stash( name => 'Foo Foo' );
}

__PACKAGE__->meta->make_immutable;
