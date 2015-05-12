package EPrints::Plugin::Import::MARC::ConcordiaTheses;

=head1 NAME

EPrints::Plugin::Import::MARC::ConcordiaTheses -- allows to import MARC records from Theses

=head1 DESCRIPTION

This plugin allows you to import MARC records into GNU EPrints.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE

(C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>
(C) 2008-2009 Helge Knüttel <helge.knuettel@bibliothek.uni-regensburg.de>
(C) 2009 Tomasz Neugebauer <tomasz.neugebauer@concordia.ca>
(C) 2011 Bin Han <bin.han@concordia.ca>
This module is free software under the same terms of Perl.

=cut

use Encode;
use strict;
use utf8;

our @ISA = qw/EPrints::Plugin::Import::MARC/;

my $CACHE_BASE_PATH = "/home/eprints/theses/concordia/import/";
my $HTML_CACHE_PATH = $CACHE_BASE_PATH."html/";
my $JPG_CACHE_PATH = $CACHE_BASE_PATH."cover_image/";

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "MARC (Concordia Theses)";
	$self->{visible} = "all";
	$self->{produce} = [ 'list/eprint' ];
	# $self->{disable} = 1;	# Disable by default; need to specifically enable in archive's plugin.pl.

	my $rc = EPrints::Utils::require_if_exists("HTML::TokeParser")
			and EPrints::Utils::require_if_exists("MARC::File::USMARC");
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

	##TN Proquest ID from 009
	if (defined $marc->field('009')){
		$epdata->{pq_id} = $marc->field('009')->as_string();
	}
	
	#BH, thesis_advisors is a multiple field
	my @listhadvisor = $plugin->get_personal_names( $marc, '599' );
	foreach my $advisor (@listhadvisor)
	{
		push @{$epdata->{thesis_advisors_name}}, $advisor;
	}

	##TN Theses link back to CLUES based on call number in 090a
	if (defined $marc->subfield('090', 'a')){
		$epdata->{related_url}=[{'url' => "http://clues.concordia.ca/search/c?SEARCH=".$marc->subfield('090', 'a')}];
	}

	##TN Theses degree name
	my $degree_name=$marc->subfield('710', 't');
	if (defined $degree_name){
		if ( $degree_name =~ /^(Theses|Research papers|Major reports) \((.+)\)$/ )
		{
			$epdata->{thesis_degree_name} = $2;
		}
		else
		{
			$epdata->{thesis_degree_name} = $degree_name;
		}
		#print STDERR "Degree Name:$degree_name\n";
		#$epdata->{thesis_degree_name} = $marc->field('710')->as_string();
	}
	else {
		print STDERR "warning: could not find degree name in 720t\n";
		$degree_name=$marc->subfield('502','a');
		print STDERR "using 502a instead: $degree_name\n";
	}

	###TN	Theses type
	my $str_theses_type = $marc->subfield('710', 't');
	if ( defined $str_theses_type )
	{
		if ($str_theses_type =~ /Theses \(P/)
		{
			$epdata->{thesis_type}="phd";
		}
		elsif ($str_theses_type =~ /Theses \(D/){
			$epdata->{thesis_type}="engd";
		}
		elsif ($str_theses_type =~ /Theses/){
			$epdata->{thesis_type}="masters";
		}
		else {
			$epdata->{thesis_type}="other";
			###TN "Research Papers"
			if ($str_theses_type =~ /Research Paper/i)
			{
			print STDERR "Series: Research Papers.\n";

				$epdata->{series}="Research Paper";
				
			}
			###TN "Theory Papers"
			if ($str_theses_type =~ /Theory Paper/i)
			{
			print STDERR "Series: Theory Papers.\n";

				$epdata->{series}="Theory Paper";
				
			}
			###TN "Major Technical Reports"
			if ($str_theses_type =~ /Major Technical Report/i)
			{
			print STDERR "Series: Major Technical Report.\n";

				$epdata->{series}="Major Technical Report";
				
			}
			###TN "Original Essay"
			if ($str_theses_type =~ /Major Technical Report/i)
			{
			print STDERR "Series: Original Essay.\n";
				$epdata->{series}="Original Essay";
			}

		}
	}

	###TN	Theses Department Mapping

	#get depatment name from 502
	my $str_502a = $marc->subfield('502', 'a');
	my $str_710b = $marc->subfield('710', 'b');
	if (defined $str_502a)
	{
		if (name_department($str_502a) eq "Ecole des hautes e´tudes commerciales" 
				or name_department($str_502a) eq "McGill University" 
				or name_department($str_502a) eq "Universite´ de Montre´al" 
				or name_department($str_502a) eq "Universite´ du Que´bec a` Montre´al")
		{
			$epdata->{note} = name_department($str_502a);
		}
		else
		{
			$epdata->{department} = name_department($str_502a);
		}
		$epdata->{divisions} = name_division($str_502a);
	}
	elsif (defined $str_710b)
	{
		if (name_department($str_710b) eq "Ecole des hautes e´tudes commerciales" 
				or name_department($str_710b) eq "McGill University" 
				or name_department($str_710b) eq "Universite´ de Montre´al" 
				or name_department($str_710b) eq "Universite´ du Que´bec a` Montre´al")
		{
			$epdata->{note} = name_department($str_710b);
		}
		else
		{
			$epdata->{department} = name_department($str_710b);
		}
		$epdata->{divisions} = name_division($str_710b);
	}
	else
	{
		#str_theses_department is undefined - not found in 502 or 710
		$epdata->{divisions}=[ 'concordia' ];
		print STDERR "Failed to find department in 502 or 710 - defaulted to Concordia University.\n";
	}

	return $epdata;
}


sub name_department
{
	my $str_theses_department = shift;
	
	if ($str_theses_department =~ m/(Art History) Dept.[^,]*,/)
	{
		return $1;
	}
	elsif($str_theses_department =~ m/(Building, Civil and Environmental Engineering)/)
	{
		return $1;
	}
	elsif($str_theses_department =~ m/(Geography, Planning, and Environment)/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/Dept\.\sof\s([^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/Dept\.\sof\s([^.]*)./)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Center\. [^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(E´cole[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Ecole[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(De´partement[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Département[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Département[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Centre [^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/Faculty\sof\s([^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Institute[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Special Individual[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Humanities[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(TESL[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(John Molson[^,]*),/)
	{
		return $1;
	}
	elsif($str_theses_department =~ m/(Mel Hoppenheim School of Cinema),/)
	{
		return $1;
	}
	# return "School of Graduate Studies"
	elsif ($str_theses_department =~ m/(School of Graduate Studies)/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(School[^,]*),/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Faculty[^\-]*)\-/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Ecole[^\.]*)\./)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Programme[^\-]*)\-/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Programme[^\.]*)\./)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Programme[^\]]*)\]/)
	{
		return $1;
	}
	elsif ($str_theses_department =~ m/(Public Policy[^\,]*)\,/)
	{
		return $1;
	}
	#special note for joint programmes with other universities
	elsif (($str_theses_department =~ m/Ecole des hautes e´tudes commerciales/) || ($str_theses_department =~ m/Ecole des hautes etudes commerciales/i)){
		return "Ecole des hautes e´tudes commerciales";
	}
	elsif ($str_theses_department =~ m/McGill University/){
		return "McGill University";
	}
	elsif ($str_theses_department =~ m/Universite´ de Montre´al/){
		return "Universite´ de Montre´al";
	}
	elsif ($str_theses_department =~ m/Universite´ du Que´bec a` Montre´al/){
		return "Universite´ du Que´bec a` Montre´al";
	}
	else {
		#could not transcribe department name from 502a
		print "Failed to transcribe department - $str_theses_department \n";
	}
}

sub name_division
{
	my $str_theses_department = shift;
	
	if ($str_theses_department =~ /Theological/i){
		return [ 'dep_theology' ];
	}
	elsif ($str_theses_department =~ /Theology/i){
		return [ 'dep_theology' ];
	}
	elsif ($str_theses_department =~ /Biology/i){
		return [ 'dep_biology' ];
		if ($str_theses_department =~ /Chemistry/i){
			return [ 'dep_biology', 'dep_chembiochem' ];
		}
	}
	elsif ($str_theses_department =~ /Chemistry/i){
		return [ 'dep_chembiochem' ];
	}
	elsif ($str_theses_department =~ /Communication/i){
		return [ 'dep_comms' ];
	}
	elsif ($str_theses_department =~ /Media/i){
		return [ 'dep_media' ];
	}
	elsif ($str_theses_department =~ /Economics/i){
		return [ 'dep_economics' ];
	}
	elsif ($str_theses_department =~ /TESL Centre/i){
		return [ 'dep_tesl' ];
	}
	elsif ($str_theses_department =~ /Applied Linguistics/i){
		return [ 'dep_applinguistics' ];
	}
	elsif ($str_theses_department =~ /English/i){
		return [ 'dep_english' ];
	}
	elsif ($str_theses_department =~ /Exercise/i){
		return [ 'dep_exercisesci' ];
	}
	elsif ($str_theses_department =~ /francaises/i){
		return [ 'dep_etudesfr' ];
	}
	elsif ($str_theses_department =~ /françaises/i){
		return [ 'dep_etudesfr' ];
	}
	elsif ($str_theses_department =~ /françaises/i){
		return [ 'dep_etudesfr' ];
	}
	elsif ($str_theses_department =~ /franc¸aises/i){
		return [ 'dep_etudesfr' ];
	}
	elsif ($str_theses_department =~ /Geography/i){
		return [ 'dep_geography' ];
	}
	elsif ($str_theses_department =~ /Hist\./i){
		return [ 'dep_history' ];
	}
	elsif ($str_theses_department =~ /History/i){
		if ($str_theses_department =~ /Art History/i){
			return [ 'dep_arthist' ];
		}
		else
		{
			return [ 'dep_history' ];
		}
	}
	elsif ($str_theses_department =~ /Mathematics/i){
		return [ 'dep_mathstats' ];
	}
	elsif ($str_theses_department =~ /Philosophy/i){
		return [ 'dep_philosophy' ];
	}
	elsif ($str_theses_department =~ /Physics/i){
		return [ 'dep_physics' ];
	}
	elsif ($str_theses_department =~ /Political/i){
		return [ 'dep_polisci' ];
	}
	elsif ($str_theses_department =~ /Psychology/i){
		return [ 'dep_psychology' ];
	}
	elsif ($str_theses_department =~ /Religion/i){
		return [ 'dep_religion' ];
	}
	elsif ($str_theses_department =~ /Sociology/i){
		return [ 'dep_sociology' ];
	}
	elsif ($str_theses_department =~ /Anthropology/i){
		return [ 'dep_sociology' ];
	}
	elsif ($str_theses_department =~ /Building/i){
		return [ 'dep_buildingcivileng' ];
	}
	elsif ($str_theses_department =~ /Civil/i){
		return [ 'dep_buildingcivileng' ];
	}
	elsif ($str_theses_department =~ /Environmental/i){
		return [ 'dep_buildingcivileng' ];
	}
	elsif ($str_theses_department =~ /Electrical/i){
		return [ 'dep_ece' ];
	}
	elsif ($str_theses_department =~ /Mechanical/i){
		return [ 'dep_mechind' ];
	}
	elsif ($str_theses_department =~ /Computer/i){
		return [ 'dep_csse' ];
	}
	elsif ($str_theses_department =~ /Information Systems Engineering/i){
		 return [ 'dep_ciise' ];
	}
	elsif ($str_theses_department =~ /Art Education/i){
		if ($str_theses_department =~ /Arts? Therap/i){
			return [ 'dep_arted', 'dep_creativearttherapies' ];
		}
		else
		{
			return [ 'dep_arted' ];
		}
	}
	elsif ($str_theses_department =~ /Arts? Therap/i){
		return [ 'dep_creativearttherapies' ];
	}
	elsif ($str_theses_department =~ /par les arts/i){
		return [ 'dep_creativearttherapies' ];
	}
	elsif ($str_theses_department =~ /Education/i){
		return [ 'dep_education' ];
	}
	elsif ($str_theses_department =~ /Art History/i){
		return [ 'dep_arthist' ];
	}
	elsif ($str_theses_department =~ /Cinema/i){
		return [ 'dep_cinema' ];
	}
	elsif ($str_theses_department =~ /Accountancy/i){
		return [ 'dep_accountancy' ];
	}
	elsif ($str_theses_department =~ /Finance/i){
		return [ 'dep_finance' ];
	}
	elsif ($str_theses_department =~ /of Management/i){
		return [ 'dep_management' ];
	}
	elsif ($str_theses_department =~ /Decision Sciences/i){
		return [ 'dep_dsmis' ];
	}
	elsif ($str_theses_department =~ /Management Information Systems/i){
		return [ 'dep_dsmis' ];
	}
	elsif ($str_theses_department =~ /Marketing/i){
		return [ 'dep_marketing' ];
	}
	elsif ($str_theses_department =~ /Special Individual Program/i){
		return [ 'fac_sgs' ];
	}
	elsif ($str_theses_department =~ /School of Graduate Studies/i){
		return [ 'fac_sgs' ];
	}
	elsif ($str_theses_department =~ /Humanities Doctoral/i){
		return [ 'fac_sgs' ];
	}
	elsif ($str_theses_department =~ /Humanities/i){
		return [ 'fac_sgs' ];
	}
	elsif ($str_theses_department =~ /Special Individualized/i){
		return [ 'fac_sgs' ];
	}
	#didn't match on department, try to see if the Faculty is listed instead 		
	elsif ($str_theses_department =~ /John Molson School of Business/i){
		return [ 'fac_jmsb' ];
	} 	
	elsif ($str_theses_department =~ /Commerce and Administration/i){
		return [ 'fac_jmsb' ];
	} 	
	elsif ($str_theses_department =~ /Faculty of Arts/i){
		#return [ 'fac_jmsb' ];
		return [ 'fac_artsscience' ];
	}
	elsif ($str_theses_department =~ /Engineering/i){
		return [ 'fac_eng' ];
	} 	
	elsif ($str_theses_department =~ /Comp\.Sci\./i){
		return [ 'dep_csse' ];
	} 	
	elsif ($str_theses_department =~ /Fine Arts/i){
		return [ 'fac_finearts' ];
	} 
	else {
		#didn't match on any of the names
		return [ 'concordia' ];
		print STDERR "Failed to match faculty/department - $str_theses_department - defaulted to Concordia University.\n";
	}
}

1;
