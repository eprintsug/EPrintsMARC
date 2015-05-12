package EPrints::Plugin::Export::MARC::ASCII;

=head1 NAME

EPrints::Plugin::Export::MARC -- allows to export eprints in MARC21

=head1 DESCRIPTION

This plugin allows you to export GNU EPrints records as MARC21, in ASCII (for staff), MARC21 and MARC-XML where needed.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE

(C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>
This module is free software under the same terms of Perl.

=cut

use strict;

our @ISA = ('EPrints::Plugin::Export::MARC');

sub new
{
        my ($class, %opts) = @_;

        my $self = $class->SUPER::new(%opts);

        $self->{name} = 'MARC (ASCII)';
        $self->{accept} = [ 'dataobj/eprint', 'list/eprint' ];
        $self->{visible} = 'all';
        $self->{suffix} = '.txt';
        $self->{mimetype} = 'text/plain; charset=utf-8';
		
        return $self;
}

sub output_dataobj
{
    my ($plugin, $dataobj) = @_;

	my $ref = EPrints::Plugin::Export::MARC::output_dataobj($plugin, $dataobj);
	my $record = ${$ref};

	# Subclassed the hard work, bye.
	return $record->as_formatted()."\n";

}

1;
