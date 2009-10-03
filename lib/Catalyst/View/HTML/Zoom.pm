package Catalyst::View::HTML::Zoom;
use Moose;
use Method::Signatures::Simple;
use HTML::Zoom;
use File::Slurp qw/read_file/;
use namespace::autoclean;

extends 'Catalyst::View';

method process ($c) {
    my $template_fn = $c->stash->{template} || "" . $c->action;
    my $template = $c->path_to('root', $template_fn);
    die("Cannot find template $template_fn") unless -r $template;
    $c->body($self->render($c, $template, $c->stash));
}

method render ($c, $template, $args) {
    my $contents = read_file($template);
    my ($body, $fh);
    open($fh, '>', \$body) or die $!; 
    HTML::Zoom->from_string($contents)
        ->add_selectors(%$args)
        ->stream_to($fh)
        ->render;
    close($fh);
    return $body;
}

=head1 NAME

Catalyst::View::HTML::Zoom - Catalyst view to HTML::Zoom

=head1 SYNOPSIS

    package MyApp::View::HTML;
    use Moose;
    
    extends 'Catalyst::View::HTML::Zoom';
    
    __PACKAGE__->meta->make_immutable;
    
=head1 METHODS

=head1 process

Renders the template specified in $c->stash->{template} or $c->action (the private name of the matched action).
Calls render to perform actual rendering. Output is stored in $c->response->body.

=head2 render($c, $template, \%args)

Renders the given template and returns output, or a Template::Exception object upon error.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 Tomas Doran.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
