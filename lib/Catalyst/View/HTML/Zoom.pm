package Catalyst::View::HTML::Zoom;
# ABSTRACT: Catalyst view to HTML::Zoom

use Moose;
use Class::MOP;
use HTML::Zoom;
use Path::Class ();
use namespace::autoclean;

extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has template_extension => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_template_extension',
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => 'text/html; charset=utf-8',
);

has root_prefix => (
    is => 'ro',
    lazy_build => 1,
);

sub _build_root_prefix {
    shift->_application->config->{root};
}

sub process {
    my ($self, $c) = @_;    
    my $template_path_part = $self->_template_path_part_from_context($c);
    if(my $out = $self->render($c, $template_path_part)) {
        $c->response->body($out);
        $c->response->content_type($self->content_type)
          unless ($c->response->content_type);
        return 1;
    } else {
        $c->log->error("The template: $template_path_part returned no response");
        return 0;
    }
}

sub _template_path_part_from_context {
    my ($self, $c) = @_;
    my $template_path_part = $c->stash->{template} || $c->action->private_path;
    if ($self->has_template_extension) {
        my $ext = $self->template_extension;
        $template_path_part = $template_path_part . '.' . $ext
          unless $template_path_part =~ /\.$ext$/;
    }
    return $template_path_part;
}

sub render {
    my ($self, $c, $template_path_part, $args) = @_;
    my $zoom = $self->_build_zoom_from($template_path_part);
    my $zoomer_class = $self->_zoomer_class_from_context($c);
    my $zoomer = $self->_build_zoomer_from($zoomer_class);
    my $action = $self->_target_action_from_context($c);

    LOCALIZE_ZOOM: {
        local $_ = $zoom;
        my $vars =  {$args ? %{ $args } : %{ $c->stash }};
        return $zoomer->$action($vars)->to_html;
    }
}

sub _build_zoom_from {
    my ($self, $template_path_part) = @_;
    if(ref $template_path_part) {
        return $self->_build_zoom_from_html($$template_path_part);
    } else {
        my $template_abs_path = $self->_template_abs_path_from($template_path_part);
        return $self->_build_zoom_from_file($template_abs_path);
    }
}

sub _build_zoom_from_html {
    my ($self, $html) = @_;
    $self->_application->log->debug("Building HTML::Zoom from direct HTML");
    HTML::Zoom->from_html($html);
}

sub _build_zoom_from_file {
    my ($self, $file) = @_;
    $self->_application->log->debug("Building HTML::Zoom from file $file");
    HTML::Zoom->from_file($file);
}

sub _template_abs_path_from {
    my ($self, $template_path_part) = @_;
    Path::Class::dir($self->root_prefix, $template_path_part);
}

sub _zoomer_class_from_context {
    my ($self, $c) = @_;
    my $controller = $c->controller->meta->name;
    $controller =~ s/^.*::Controller::(.*)$/$1/;
    my $zoomer_class = do {
        $c->stash->{zoom_class} ||
          join('::', ($self->meta->name, $controller));
    };
    $self->_application->log->debug("Using View Class: $zoomer_class");
    Class::MOP::load_class($zoomer_class);
    return $zoomer_class;
}

sub _build_zoomer_from {
    my ($self, $zoomer_class) = @_;
    my $key = $zoomer_class;
    $key =~s/^.+::(View)/$1/;
    my %args = %{$self->_application->config->{$key} || {}};
    return $zoomer_class->new(%args);
}

sub _target_action_from_context {
    my ($self, $c) = @_;
    return $c->stash->{zoom_action}
      || $c->action->name;
}

__PACKAGE__->meta->make_immutable;

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

=head1 ATTRIBUTES

The following is a list of configuration attributes you can set in your global
L<Catalyst> configuration or locally with the C<__PACKAGE__->config> method.

=head2 template_extension

Optionally set the filename extension of your zoomable templates.  Common
values might be 'html' or 'xhtml'

=head2 content_type

Sets the default content-type of the response body.

=head2 root_prefix

Used at the prefix path for where yout templates are stored.  Defaults to 
$c->config->{root}.  

=head1 METHODS

=head2 process ($c)

Renders the template specified in C<$c->stash->{template}> or 
C<$c->namespace/$c->action> (the private name of the matched action). Stash
contents are passed to the underlying view object.

Output is stored in C<$c->response->body> and we set the value of 
C<$c->response->content_type> to C<text/html; charset=utf-8> or whatever you
configured as the L</content_type> attribute unless this header has previously
been set.

=head2 render($c, $template, $args)

Renders the given template and returns output.

If C<$template> is a simple scalar, we assume this is a path part that combines
with the value of L</root_prefix> to discover a file that lives on your local
filesystem.

However, if C<$template> is a ref, we assume this is a scalar ref containing 
some html you wish to render directly.

=head1 WARNING: VOLATILE!

This is the first version of a Catalyst view to L<HTML::Zoom> - and we might 
have got it wrong. Please be aware that this is still in early stages, and the
API is not at all stable. You have been warned (but encouraged to break it and 
submit bug reports and patches :).

=head1 THANKS

Thanks to Thomas Doran for the initial starting point

=cut

