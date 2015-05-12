package EPrints::Plugin::Export::MARC::XML;

=head1 NAME

EPrints::Plugin::Export::MARC::XML -- allows to export eprints in MARC-XML

=head1 DESCRIPTION

This plugin allows you to export GNU EPrints records as MARC-XML. This plugin handles single items as records and lists as collections.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE

(C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>
This module is free software under the same terms of Perl.

=cut

use strict;
use MARC::File::XML;

our @ISA = ('EPrints::Plugin::Export::MARC');

sub new
{
        my ($class, %opts) = @_;

        my $self = $class->SUPER::new(%opts);

        $self->{name} = 'MARC XML';
        $self->{accept} = [ 'dataobj/eprint', 'list/eprint' ];
        $self->{visible} = 'all';
        $self->{suffix} = '.xml';
        $self->{mimetype} = 'text/xml; charset=MARC-8';

        return $self;
}

sub output_dataobj
{
        my ($plugin, $dataobj) = @_;

	my $ref = EPrints::Plugin::Export::MARC::output_dataobj($plugin, $dataobj);
	my $record = ${$ref};

	# Subclassed the hard work, bye.
	return $record->as_xml_record('USMARC');

}

sub output_list
{

	my( $plugin, %opts ) = @_;
	my $r = [];
	my $part;

	# I still subclass the hard work here, but MARC XML lists require
	# a collection wrapper which is achievable this way.

	my $print = MARC::File::XML::header() . "\n";

	foreach my $dataobj ( $opts{list}->get_records )
	{
		my $ref = EPrints::Plugin::Export::MARC::output_dataobj( $plugin, $dataobj );
		my $record = ${$ref};
		$print .= MARC::File::XML::record( $record ) . "\n";
	}

	$print .= MARC::File::XML::footer();

	if( defined $opts{fh} )
	{
		print {$opts{fh}} $print;
		return;
	} else {
		return $print;
	}

}

1;
