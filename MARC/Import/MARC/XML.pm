package EPrints::Plugin::Import::MARC::XML;

=head1 NAME

EPrints::Plugin::Import::MARC::XML -- allows to import MARC XML records

=head1 DESCRIPTION

This plugin allows you to import MARC XML records into GNU EPrints.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE

(C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>
This module is free software under the same terms of Perl.

=cut

use Encode;
use strict;

our @ISA = qw/EPrints::Plugin::Import::MARC/;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "MARC XML";
	$self->{visible} = "all";
	$self->{produce} = [ 'list/eprint' ];

	my $rc = EPrints::Utils::require_if_exists("MARC::File::XML");
	unless( $rc ) 
	{
		$self->{visible} = "";
		$self->{error} = "Failed to load required modules.";
	}

	return $self;
}

sub input_fh
{
	my( $plugin, %opts ) = @_;
	
	my @ids;
	my $file = MARC::File::XML->in( $opts{fh} );

	while ( my $marc = $file->next() ) {
		my $epdata = EPrints::Plugin::Import::MARC::convert_input( $marc );
		next unless( defined $epdata );

		my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
		if( defined $dataobj )
		{
			push @ids, $dataobj->get_id;
		}
	}

	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $plugin->{session},
		ids=>\@ids );

	return undef;
}

sub input_file
{
	my( $plugin, %opts ) = @_;

	if( $opts{filename} eq '-' )
	{
		$plugin->error("Does not support input from STDIN");

		return undef;
	}

	my @ids;
	my $file = MARC::File::XML->in( $opts{filename} );

	while ( my $marc = $file->next() ) {
		my $epdata = $plugin->EPrints::Plugin::Import::MARC::convert_input( $marc );
		next unless( defined $epdata );

		my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
		if( defined $dataobj )
		{
			push @ids, $dataobj->get_id;
		}
	}

	return EPrints::List->new( 
		dataset => $opts{dataset}, 
		session => $plugin->{session},
		ids=>\@ids );
}

1;
