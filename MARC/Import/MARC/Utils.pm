package EPrints::Plugin::Import::MARC::Utils;

=head1 NAME

EPrints::Plugin::Import::MARC::Utils -- Utilities to help importing MARC records

=head1 DESCRIPTION

This module provides utilities to aid importing of MARC and MARC XML records into GNU EPrints. 
See EPrints::Plugin::Import::MARC.pm and e.g. EPrints::Plugin::Import::MARC::Safari.pm.

= CONFIGURATION

Still to come.

=head1 COPYRIGHT AND LICENSE

(C) 2008 Helge Knüttel <helge.knuettel@bibliothek.uni-regensburg.de>
This module is free software under the same terms of Perl.

=cut

use Encode;
use strict;

use File::Copy "mv";
use File::Temp;
# use HTML::TokeParser;
# use HTML::FormatText;
# use HTML::TreeBuilder;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;


my $DEBUG = 1;
my $USE_ALREADY_DOWNLOADED_WEB_FILES = 1;
my $GET_MAX_TRIES = 5;
my $PAUSE_SECONDS_BETWEEN_DOWNLOADS = 1;

sub new
{
	my $self = {};
	bless $self;

	my $ua = init_user_agent();
	$self->{user_agent} = $ua;	# Store HTTP user agent with object and thus keep session cookies.
								# This seems to help with Safari.

	return $self;
}

=item my ($response, $tmp_file) = get_webfile( $url, [$filename [, $content_type_allowed ] ])

=cut
sub get_webfile
{
	my $self = shift;
	my $url = shift;
	my $filename = shift;
	my $content_type_allowed = shift;
	$content_type_allowed = "" unless defined $content_type_allowed;
	if ( $USE_ALREADY_DOWNLOADED_WEB_FILES && ( $filename ) && ( -e $filename ) ) 
	{
		printd( "File $filename already exists. Using this one." );
		return undef, $filename;
	}
	else
	{
		my $ua = $self->{user_agent};
		my $response;
		my $download_attempts = 0;
		$response = $ua->head( $url );
		my $content_type = $response->header( "Content-Type" );
		if ( $content_type_allowed ) 
		{
			unless ( $content_type eq $content_type_allowed )
			{
				printd( "File is of wrong content type \"" . $content_type . "\". Allowed is \"$content_type_allowed\". URL: $url" );
				return undef, undef;
			}
		}
		my $fh = new File::Temp( UNLINK => 0, TEMPLATE => 'safari_XXXXXX', DIR => '/tmp' );
		my $tmp_file = $fh->filename();
		sleep $PAUSE_SECONDS_BETWEEN_DOWNLOADS;	# Wait a while to not bomb server.
		do
		{
			$download_attempts++;
			printd( "Trying to get file (attempt $download_attempts): $url\n" );
			$response = $ua->get( 
					$url,
					':content_file' => $tmp_file );
			if ($response->is_success) 
			{
				printd( "Done. Content saved to $tmp_file\n" );
			}
			else
			{
				print STDERR "ERROR: Could not get file $url\n    ", $response->status_line, "\n";
			}
			sleep $PAUSE_SECONDS_BETWEEN_DOWNLOADS;
		}
		until ( $response->is_success || ( $download_attempts >= $GET_MAX_TRIES ) );

		if ( $response->is_success )
		{
			if ( $filename ) # A filename was given when calling this sub so move temp file to that one.
			{
				if ( mv( $tmp_file, $filename ) )
				{
					#$fh->unlink_on_destroy( 0 );	# Do not try to unlink this file anymore as it was moved already.
					printd( "Moved content to $filename\n" );
					return $response, $filename;
				}
				else
				{
					printd( "Could not move temp file ", $tmp_file, " to $filename: $!\n" );
				}

			}
			return $response, $tmp_file;
		}
		else
		{
			print STDERR "ERROR: Could not get file $url while trying $GET_MAX_TRIES times. Aborting attempts.\n";
			return $response, undef;
		}
	}
}

sub init_user_agent
{
	my $ua = LWP::UserAgent->new;
	# Must allow cookies! Springer has some strange redirects that work with cookies.
	$ua->cookie_jar({}); # Allow for cookies to be stored in memory
	$ua->agent( "Mozilla/5.0 (Windows; U; Windows NT 5.1; en; rv:1.8.1.1) Gecko/2006120418 Firefox/2.0.0.1" );
	$ua->default_header( 'Referer' => 'http://ebooks-test.bibliothek.uni-regensburg.de/' );
	$ua->default_header( 'Accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5' );
	$ua->default_header( 'Accept-Language' => 'en-us,en;q=0.8' );
	#$ua->default_header( 'Accept-Encoding' => 'gzip,deflate' );
	$ua->default_header( 'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7' );
	$ua->default_header( 'Keep-Alive' => '300' );
	$ua->default_header( 'Connection' => 'keep-alive' );
	return $ua;
}

sub printd
{
	print STDERR @_, "\n" if $DEBUG;
}

1;
