package EPrints::Plugin::Import::MARC;

=head1 NAME

EPrints::Plugin::Import::MARC -- allows to import MARC records

=head1 DESCRIPTION

This plugin allows you to import MARC and MARC XML records into GNU EPrints.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE
(C) 2009 Tomasz Neugebauer <tomasz.neugebauer@concordia.ca>
(C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>
(C) 2008-2009 Helge Knüttel <helge.knuettel@bibliothek.uni-regensburg.de>
This module is free software under the same terms of Perl.

=cut

use Encode;
use strict;

our @ISA = qw/EPrints::Plugin::Import/;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "MARC";
	$self->{visible} = "all";
	$self->{produce} = [ 'list/eprint' ];
	#$self->{disable} = 1;


	my $rc = EPrints::Utils::require_if_exists("MARC::Record") and EPrints::Utils::require_if_exists("MARC::File::USMARC");
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

	my $file = MARC::File::USMARC->in( $opts{fh} );

	my @ids = $plugin->convert_marc_file( $file, $opts{dataset} );

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
	else {
		print STDERR "-----input_file:",$opts{filename},"------------\n";
	}

	my $file = MARC::File::USMARC->in( $opts{filename} );

	my @ids = $plugin->convert_marc_file( $file, $opts{dataset} );

	return EPrints::List->new(
		dataset => $opts{dataset},
		session => $plugin->{session},
		ids=>\@ids );
}

sub convert_input
{

	my ( $plugin, $marc ) = @_;
	my $epdata = (); # to be returned

	my $class = ref( $plugin );
	my %mappings = ();
	if ( $plugin->{session}->get_repository->get_conf( "marc" )->{$class}->{marc2ep} )
	{
		%mappings = %{ $plugin->{session}->get_repository->get_conf( "marc" )->{$class}->{marc2ep} };
	}
	unless ( %mappings )	# No plugin specific mappings: use default.
	{
		%mappings= %{$plugin->{session}->get_repository->get_conf( "marc" )->{marc2ep}};
	}

	foreach my $field ( $marc->fields() )	# each field of the record
	{
		my $t = $field->tag();
		my @list = grep ( /^$t/, keys %mappings );  # lookup for mappings
		foreach my $i ( sort @list )
		{
			( my $s ) = $i =~ /$t(.)/;          # mapped subfield
			my $ts = $t . $s;                   # complete tag+subfield
			my $value = $field->as_string($s);
			my $metafield = EPrints::Utils::field_from_config_string(
                    $plugin->{session}->get_repository->get_dataset( "eprint" ), $mappings{$ts} );
			##TN-commenting out due to runtime error.
		if( $metafield->get_property( "multiple" ) )
		{
			push @{$epdata->{$mappings{$ts}}}, $value if $value;
		}
		else
		{
				$epdata->{$mappings{$ts}} = $value;
		}
		}
	}

##TN import into "inbox" status, change to archive, buffer, eprint
$epdata->{eprint_status}="inbox";

##TN separator for error ouput
print STDERR "----------------------------------------------\n";

#TN deal with 245
	my $str_theses_title = $marc->subfield('245', 'a');
	my $str_theses_subtitle = $marc->subfield('245', 'b');

	if ( defined $str_theses_title ){
		$str_theses_title =~ s/ *$//; #remove trailing space
		$str_theses_title  =~ s/\/+$//; #remove trailing "/"
		$epdata->{title}=$str_theses_title;
		if ( defined $str_theses_subtitle ){
			$str_theses_subtitle =~ s/ *$//; #remove trailing space
			$str_theses_subtitle  =~ s/\/+$//; #remove trailing "/"
			$epdata->{title}=$str_theses_title." ".$str_theses_subtitle;
		}
	}

	##TN deal with 300
	if (defined $marc->field('300')){
		$epdata->{pages_aacr} = $marc->field('300')->as_string();
	}

	###	Persons
	# Persons may either be creators or editors
	# Main entry personal name: field 100
	my $contributors = [];
	push( @$contributors, $plugin->get_personal_names( $marc, '100' ) );
	# Field 700 for additional contributors
	push( @$contributors, $plugin->get_personal_names( $marc, '700' ) );
	# Decide if persons are creators (authors) or editors.
	# This might not be true for all MARC records!!!
	my $contributors_line = $marc->subfield('245', 'c');

	#TN - changed this to default creators instead of looking for "edited by"
	if ($contributors){
		$epdata->{creators_name} = $contributors;
	}
	else {
		#warning - no contributors/authors found in 100 or 700
		print STDERR "warning - no contributors/authors found in 100 or 700.\n";
	}

	if ( defined $contributors_line )
	{
		if ( $contributors_line =~ m/^edited by/ )
		{
			# Contributors are editors
	#		$epdata->{editors_name} = $contributors;
		}
		else
		{
			# Contributors are creators
	#		$epdata->{creators_name} = $contributors;
		}
	}
	else {
		#warning - there was no 245c
		print STDERR "warning - there was no 245c found in the record.\n";

	}

	# Constants
	my %constants = ();
	if ( $plugin->{session}->get_repository->get_conf( "marc" )->{$class}->{constants} )
	{
		 %constants = %{$plugin->{session}->get_repository->get_conf( "marc" )->{$class}->{constants}};
	}
	unless ( %constants )	# No plugin specific constants: use default.
	{
		%constants = %{$plugin->{session}->get_repository->get_conf( "marc" )->{marc2ep}->{constants}};
	}
	foreach my $const ( keys %constants )
	{
		my $metafield = EPrints::Utils::field_from_config_string(
            	$plugin->{session}->get_repository->get_dataset( "eprint" ), $const );
		if ( defined $metafield && $metafield->get_property( "multiple" ) )
		{
			push @{$epdata->{$const}}, $constants{$const};
		}
		else
		{
			$epdata->{$const} = $constants{$const};
		}
	}


	# Hook for derived classes to handle additional specific stuff.
	$epdata = $plugin->handle_marc_specialities( $epdata, $marc );

	return $epdata;

}

=item my @ids = $plugin->convert_marc_file( $file, $dataset );

Converts a MARC::File::USMARC into eprint(s) in the dataset given.

Returns a list of the ids of the eprints imported.

=cut
sub convert_marc_file
{
	my ($plugin, $file, $dataset ) = @_;
	my @ids = ();
	if (defined $file){
		print STDERR "-----processing ",$file,"------------\n";
	}
	else{
		print STDERR "ERROR: undefined input file\n";
	}
	while ( my $marc = $file->next() ) {
		my $epdata = $plugin->convert_input( $marc );
		next unless( defined $epdata );

		my $dataobj = $plugin->epdata_to_dataobj( $dataset, $epdata );
	#	$dataobj = $plugin->post_process_eprint( $dataobj, $epdata, $marc );
		if( defined $dataobj )
		{
			push @ids, $dataobj->get_id;
		}
	}
	return @ids;
}

=item $eprint = $plugin->post_process_eprint( $eprint, $epdata, $marc )

This is a hook to do any postprocessing of an eprint already imported from MARC
such as adding documents.

No changes to the data are done in this method. It is provided to be overridden
in subclassed plugins dealing with specific MARC records. See also
handle_marc_specialities.

=cut
sub post_process_eprint
{
	my ( $plugin, $eprint, $epdata, $marc ) = @_;
	return $eprint;
}

=item $epdata = $plugin->handle_marc_specialities( $epdata, $marc );

This is a hook to do additional handling when converting a MARC record to a hash
reference of metadata. epdata is then used to create an eprint. See also
post_process_eprint.

No changes to the data are done in this method. It is provided to be overridden
in subclassed plugins dealing with specific MARC records.

=cut
sub handle_marc_specialities
{
	my ( $plugin, $epdata, $marc ) = @_;
	return $epdata;
}

=item my @contributors = get_names( $marc, $field );

Extract parts of names from MARC fields 100 or 700.  599 contains advisor name (thesis) which is local to Concordia.

Parameters: MARC::Field (100 or 700 or 599), MARC field name (i.e. '100' or '700')

Returns: A list of hashes with given name, first name, honourific part.
=cut
sub get_personal_names
{
		my ( $plugn, $marc, $field) = @_;
		my @contributors = ();
		my @fields = $marc->field( $field );
		foreach my $field ( @fields )
		{
			my $contributor = $field->subfield("a");
			next unless defined $contributor;
			my ( @name, $given, $family, $honourific );
			@name = split(/,/, $contributor);
			if (( $field->indicator(1) eq '1' ) || ($field->tag() eq '599'))
			{
				$given = $name[1];
				if ( defined $given )
				{
					$given =~ s/^\s//;
				}
				$family = $name[0];
			}
			else
			{
				$given = $name[0];
				$family = $name[1];
				if ( defined $family )
				{
					$family =~ s/^\s//;
				}
			}
			# Remove trailing period in given name
			if( defined $given )
			{
				$given =~ s/\.$//;
			}
			$honourific = $field->subfield("c");
			push( @contributors, { 'given'=>$given, 'family'=>$family, 'honourific'=>$honourific });
		}
		return @contributors;
}

1;