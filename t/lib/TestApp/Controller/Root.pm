package TestApp::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => q{});


sub main :Path {
    my ($self, $c) = @_;
    $c->stash( name => 'Dave' );
}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;
