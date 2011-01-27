package Catalyst::View::HTML::Zoom;
# ABSTRACT: Catalyst view to HTML::Zoom
use Moose;
use HTML::Zoom;
use MooseX::Types::Moose qw( Maybe );
use MooseX::Types::Common::String qw( NonEmptySimpleStr );
use namespace::autoclean;

extends 'Catalyst::View';

__PACKAGE__->config( template_extension => undef );

has template_extension => (
    is       => 'ro',
    isa      => Maybe[NonEmptySimpleStr],
    required => 1
);

sub process {
    my ($self, $c) = @_;
    my $template_fn = $c->stash->{template} || "" . $c->action;
    if (my $ext = $self->template_extension) {
        $template_fn = $template_fn . '.' . $ext
            unless $template_fn =~ /\.$ext$/;
    }

    my $template = $c->path_to('root', $template_fn);
    die("Cannot find template $template_fn") unless -r $template;

    $c->res->body($self->render($c, $template->stringify));
}

sub render {
    my ($self, $c, $template) = @_;
    my $zoom = $self->_build_zoom($template);
    my $controller = $c->controller->meta->name;
    $controller =~ s/^.*::(.*)$/$1/;

    my $zoomer_class = join '::', ($self->meta->name, $controller);
    
    Class::MOP::load_class($zoomer_class);
    my $zoomer = $zoomer_class->new;
    my $action = $self->_target_action_from_context($c);

    {
        local $_ = $zoom;
        return $zoomer->$action($c->stash)->to_html;
    }
}

sub _target_action_from_context {
    my ($self, $c) = @_;
    return $c->stash->{zoom_action}
      || $c->action->name;
}

sub _build_zoom {
    my ($self, $template) = @_;
    return ref $template ? 
      HTML::Zoom->from_html($$template) :
      HTML::Zoom->from_file($template);
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

    package MyApp::View::HTML::Wobble;
    use Moose;
    sub dance {
        my ($self, $stash) = @_;
        $_->select('#shake')->replace_content($stash->{shaking});
    }

    #root/wobble/dance
    <p>Shake those <span id="shake" />!</p>

    /wobble/dance => "<p>Shake those <span id="shake">hips</span>!</p>";

=head1 METHODS

=head2 process

Renders the template specified in C<$c->stash->{template}> or C<$c->namespace/$c->action>
(the private name of the matched action). Calls render to perform actual rendering.

Output is stored in $c->response->body.

=head2 render($c, $template)

Renders the given template and returns output, or a Template::Exception object upon error.

=head2 _build_zoom ($template_path|\$html)

Returns an L<HTML::Zoom> object given either a path on the filesystem or a
scalar reference containing the html text.

=head1 WARNING: VOLATILE!

This is the first version of a Catalyst view to L<HTML::Zoom> - and we might have got it wrong. Please be
aware that this is still in early stages, and the API is not at all stable. You have been warned (but
encouraged to break it and submit bug reports and patches :).

=head1 THANKS

Thanks to Thomas Doran for the initial starting point

=cut

__PACKAGE__->meta->make_immutable;
