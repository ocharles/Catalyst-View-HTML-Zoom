package Catalyst::View::HTML::Zoom;
use Moose;
use Method::Signatures::Simple;
use HTML::Zoom;
use MooseX::Types::Moose qw/HashRef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Lexical::Types qw/NonEmptySimpleStr HashRef/;
use namespace::autoclean;

extends 'Catalyst::View';

__PACKAGE__->config( stash_key => 'zoom' );

has stash_key => ( is => 'ro', isa => NonEmptySimpleStr, required => 1 );

method process ($c) {
    my NonEmptySimpleStr $template_fn = $c->stash->{template} || "" . $c->action;
    my HashRef $args = $c->stash->{$self->stash_key} || {};
    my $template = $c->path_to('root', $template_fn);
    die("Cannot find template $template_fn") unless -r $template;
    $c->res->body($self->render($c, $template, $args));
}

method render ($c, $template, $args) {
    my $contents = do {
        open(my $fh, '<', $template)
            or die $!;
        local $/;
        <$fh>;
    };
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
    
    #__PACKAGE__->config( stash_key => 'zoom' ); # This is the default
    
    __PACKAGE__->meta->make_immutable;

    # Elsewhere in a controller method

    sub foobar {
        my ($self, $c) = @_;
        # Merge pre-existing selectors
        $c->stash->{zoom} = Catalyst::Utils::merge_hashes($c->stash->{zoom}||{},
            '#name' => 'Dave'
        );
        # $c->stash->{template} = 'foobar'; # Can manually set the template, or
                                            # it defaults to your action name.
    }

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
