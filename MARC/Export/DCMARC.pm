package EPrints::Plugin::Export::DCMARC;

@ISA = ('EPrints::Plugin::Export::DC');

use strict;
use MARC::Record;
use EPrints::Plugin::Export::DC;

=head1 NAME

EPrints::Plugin::Export::DCMARC - Export plugin for MARC21 via Dublin 
Core

=head1 DESCRIPTION

This plugin allows you to export eprints in MARC21 via the Dublin Core 
unqualified crosswalk specified by the Library of Congress. This plugin 
features a staff-only ASCII export and a public USMARC export plugin.

=head1 AUTHOR

Jose Miguel Parrella Romero <bureado@cpan.org>

=head1 LICENSE

This plugin is part of GNU ePrints.

=cut

sub new
{
        my ($class, %opts) = @_;

        my $self = $class->SUPER::new(%opts);

        $self->{name} = 'MARC from Dublin Core';
        $self->{visible} = 'none';

	my $rc = EPrints::Utils::require_if_exists("MARC::Record");
	unless ( $rc ) {
		$self->{visible} = "";
		$self->{error} = "Failed to load MARC::Record";
	}

        return $self;
}

sub output_dataobj
{
        my ( $plugin, $eprint ) = @_;

	my $record = MARC::Record -> new ();

	# Unqualified DC->MARC21 mapping from LOC
	my %mappings = (
		title => '245a',
		relation => '856a',
		creator => '720a',
		contributor => '720a',
		coverage => '500a',
		date => '260c',
		description => '520a',
		format => '856q',
		identifier => '024a',
		language => '546a',
		publisher => '260b',
		relation => '787n',
		rights => '540a',
		source => '786n',
		subject => '653a',
		title => '245a',
		type => '655a',
	);

	# Getting unqualified Dublin Core for this eprint
	my $dc = EPrints::Plugin::Export::DC::output_dataobj ( $plugin, $eprint );

	# Iterate on each DC field and create mapped MARC field
	foreach my $line ( split ( "\n", $dc ) ) {

		my ( $title, $value ) = $line =~ /^(\S+):\s+(.+)$/;
		my ( $a, $b ) = $mappings{$title} =~ /(\d+)(.)/;
		my $field = MARC::Field -> new (
			$a, '', '',
			$b => $value
		);
		$record->append_fields ( $field );

	}

	# We return a MARC::Record object
	return \$record;

}

1;
