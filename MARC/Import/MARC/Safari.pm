package EPrints::Plugin::Import::MARC::Safari;

=head1 NAME

EPrints::Plugin::Import::MARC::Safari -- allows to import MARC records from Safari together with additional information from the Safari web site

=head1 DESCRIPTION

This plugin allows you to import MARC and MARC XML records into GNU EPrints.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE

(C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>
(C) 2008-2009 Helge Knüttel <helge.knuettel@bibliothek.uni-regensburg.de>
This module is free software under the same terms of Perl.

=cut

use Encode;
use strict;


our @ISA = qw/EPrints::Plugin::Import::MARC/;

my $CACHE_BASE_PATH = "/home/eprints/ebooks/safari/import/";
my $HTML_CACHE_PATH = $CACHE_BASE_PATH."html/";
my $JPG_CACHE_PATH = $CACHE_BASE_PATH."cover_image/";

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "MARC (Safari ebooks)";
	$self->{visible} = "staff";
	$self->{produce} = [ 'list/eprint' ];
	$self->{disable} = 0;	# Disable by default; need to specifically enable in archive's plugin.pl.

	my $rc = EPrints::Utils::require_if_exists("HTML::TokeParser") 
			and EPrints::Utils::require_if_exists("MARC::File::USMARC")
			and EPrints::Utils::require_if_exists("EPrints::Plugin::Import::MARC::Utils");
	unless( $rc ) 
	{
		$self->{visible} = "";
		$self->{error} = "Failed to load required modules.";
	}


	return $self;
}


sub handle_marc_specialities
{
	my ( $plugin, $epdata, $marc ) = @_;

	$epdata->{date} =~ s/[^0-9]//;
	$epdata->{place_of_pub} =~ s/\s*:\s*$//;
	$epdata->{publisher} =~ s/\s*,\s*$//;
	
	# print STDERR Data::Dumper->Dumper( $epdata );
	return $epdata;
}




sub post_process_eprint
{
	my ( $plugin, $eprint, $epdata, $marc ) = @_;
	# $eprint is undefined if $plugin->{parse_only}!

	my $utils = EPrints::Plugin::Import::MARC::Utils->new;
	# Try to find ISBN in URL.
	my $url = $epdata->{fulltext_url};
	unless ( $url )
	{
		$plugin->warning( "No URL found in item. Stopping post processing MARC imported item!\n" );
		return $eprint;
	}
	my $isbn;
	if ( $url =~ m/([\dxX]+)$/ )
	{
		$isbn = $1;
	}
	else
	{
		$plugin->warning( "No ISBN found in URL $url. Stopping to postprocess item imported from MARC!\n" );
		return $eprint;
	}

	# Try to get book's abstract page.
	$url = "http://proquest.safaribooksonline.com/" . $isbn;
	my $about_book_file = $HTML_CACHE_PATH."about_".$isbn.".html";
	my ( $response, $webfile ) = $utils->get_webfile( $url, $about_book_file );
	
	return $eprint unless $webfile;	# We were not successful in retrieving a page.

	# Extract URL of cover image.
	my $img_url = "";
	open my $page, "<:utf8", $webfile;
	my $parser = HTML::TokeParser->new( $page );
	while (my $token = $parser->get_tag("img")) 
	{
		my $src = $token->[1]{src} || "-";
		#print STDERR "Found image: $src\n";
		if ( $src =~ m/^\/images\/$isbn\// )
		{
			print STDERR "Image URL found in web page: $src\n";
			$img_url = $src;
			last;
		}
	}
	# Extract abstract.
	my $abstract = "";
	while (my $token = $parser->get_tag("div")) 
	{
		my $id = $token->[1]{id} || "-";
		if ( $id eq "overview" )
		{
			$abstract = $parser->get_trimmed_text("/div");

			$abstract =~ s/^Overview //;
			#print STDERR "Abstract: $abstract\n";
			last;
		}
	}
	close $page;

	# Try to get cover image
	my $cover_image = undef;
	my $cover_image_filename = "";
	if ( $img_url )
	{
		$img_url =~ m/([^\.]+)$/;
		my $extension = $1;
		$img_url = "http://proquest.safaribooksonline.com" . $img_url;
		$cover_image_filename = "cover_image_$isbn.$extension";
		$cover_image = $JPG_CACHE_PATH . $cover_image_filename;
		( $response, $cover_image ) = $utils->get_webfile( $img_url, $cover_image );
		print STDERR "Content-Type:", $response->header( "Content-Type" ), "\n" if ( $response );
	}
	
	# Do alter eprint unless parse_only
	if( $plugin->{parse_only} )
	{
		if( $plugin->{session}->get_noise > 1 )
		{
			print STDERR "Would have postprocessed eprint\n";
		}	
		if( $plugin->{scripted} )
		{
			print "EPRINTS_IMPORT: ITEM_POSTPROCESSED\n";
		}
		return $eprint;
	}

	# Actually change the data.
	$eprint->set_value( "abstract", $abstract ) if ( $abstract );
	$eprint->set_value( "vendor", "safari" );
	if ( $cover_image )
	{
		my $session = $plugin->{session};
		my $doc = EPrints::DataObj::Document->create_from_data( 
				$session, 
				{ eprintid=>$eprint->get_id },
				$session->get_repository->get_dataset( "document" ) );
		$doc->add_file( $cover_image, $cover_image_filename );
		$doc->set_value( "format", "cover_image" );
		$doc->commit();
	}
	$eprint->commit();


	my $dataset = $eprint->get_dataset;
	if( $plugin->{session}->get_noise > 1 )
	{
		print STDERR "Postprocessed ".$dataset->id.".".$eprint->get_id."\n";
	}	
	if( $plugin->{scripted} )
	{
		print "EPRINTS_IMPORT: ITEM_POSTPROCESSED ".$eprint->get_id."\n";
	}


	return $eprint;
}


1;
