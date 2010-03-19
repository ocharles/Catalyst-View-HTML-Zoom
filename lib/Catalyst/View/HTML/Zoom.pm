package Catalyst::View::HTML::Zoom;
# ABSTRACT: Catalyst view to HTML::Zoom
use Moose;
use Method::Signatures::Simple;
use HTML::Zoom;
use MooseX::Types::Moose qw/HashRef Undef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Lexical::Types qw/NonEmptySimpleStr HashRef/;
use namespace::autoclean;

extends 'Catalyst::View';

__PACKAGE__->config( template_extension => undef );

has template_extension => ( is => 'ro', isa => Undef|NonEmptySimpleStr, required => 1 );

method process ($c) {
    my NonEmptySimpleStr $template_fn = $c->stash->{template} || "" . $c->action;
    if (my $ext = $self->template_extension) {
        $template_fn = $template_fn . '.' . $ext
            unless $template_fn =~ /\.$ext$/;
    }

    $template_fn = $c->namespace . "/$template_fn";

    my $template = $c->path_to('root', $template_fn);
    die("Cannot find template $template_fn") unless -r $template;

    $c->res->body($self->render($c, $template));
}

method render ($c, $template) {
    my $zoom = HTML::Zoom->from_file($template);

    my $controller = $c->controller->meta->name;
    $controller =~ s/^.*::(.*)$/$1/;

    my $zoomer_class = join '::', ($self->meta->name, $controller);
    my $action = $c->action;

    Class::MOP::load_class($zoomer_class);
    my $zoomer = $zoomer_class->new;
    local $_ = $zoom;
    return $zoomer->$action($c->stash)->to_html;
}

=head1 SYNOPSIS

    package MyApp::View::HTML;
    use Moose;
    extends 'Catalyst::View::HTML::Zoom';

    package MyApp::Controller::Wobble;
    use Moose; BEGIN { extends 'Catalyst::Controller' }
    sub dance : Local {
        my ($self, $c) = @_;
        $c->stash( shaking => 'hips' );
    }

    package MyApp::View::HTML::Controller;
    use Moose;
    sub dance {
        my ($self, $stash) = @_;
        $_->select('#shake')->replace_content($stash->{shaking});
    }

    #root/wobble/dance
    <p>Shake those <span id="shake" />!</p>

    /wobble/dance => "<p>Shake those hips!</p>";

=head1 METHODS

=head1 process

Renders the template specified in C<$c->stash->{template}> or C<$c->namespace/$c->action>
(the private name of the matched action). Calls render to perform actual rendering.

Output is stored in $c->response->body.

=head2 render($c, $template)

Renders the given template and returns output, or a Template::Exception object upon error.

=head1 WARNING: VOLATILE!

This is the first version of a Catalyst view to L<HTML::Zoom> - and we might have got it wrong. Please be
aware that this is still in early stages, and the API is not at all stable. You have been warned (but
encouraged to break it and submit bug reports and patches :).

=head1 THANKS

Thanks to Thomas Doran for the initial starting point

=cut

__PACKAGE__->meta->make_immutable;
