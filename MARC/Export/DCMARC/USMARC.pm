package EPrints::Plugin::Export::DCMARC::USMARC;

@ISA = ('EPrints::Plugin::Export::DCMARC');

use strict;
use EPrints::Plugin::Export::DCMARC;
use MARC::Record;

=head1 NAME

EPrints::Plugin::Export::DCMARC::USMARC - Export plugin for MARC21 via 
Dublin Core in USMARC

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

        $self->{name} = 'MARC from DC';
        $self->{accept} = [ 'dataobj/eprint', 'list/eprint' ];
        $self->{visible} = 'none';
        $self->{suffix} = '.mrc';
        $self->{mimetype} = 'text/plain; charset=utf-8';

        return $self;
}

sub output_dataobj
{
        my ($plugin, $dataobj) = @_;

	my $ref = EPrints::Plugin::Export::DCMARC::output_dataobj($plugin, $dataobj);
	my $record = ${$ref};

	return $record->as_usmarc();

}

1;
