package EPrints::Plugin::Export::MARC;

=head1 NAME

EPrints::Plugin::Export::MARC -- allows to export eprints in MARC21

=head1 DESCRIPTION

This plugin allows you to export GNU EPrints records as MARC21, in ASCII (for staff), MARC21 and MARC-XML where needed.

=head1 CONFIGURATION

Configuration might be changed in cfg.d/marc.pl. Webserver needs to be restarted after any configuration changes.

=head1 COPYRIGHT AND LICENSE

This module is free software under the same terms of Perl.

=cut

@ISA = ('EPrints::Plugin::Export');

use strict;
use utf8;
use constant
{
	#leader field length
	LEADER_LEN => 24,
	#"%03s%04d%05d": tag, length, dataend
	DIRECTORY_ENTRY_LEN => 12,
};

sub new
{
	my ($class, %opts) = @_;

	my $self = $class->SUPER::new(%opts);

	$self->{name} = 'MARC';
	$self->{visible} = 'none';

	my $rc = EPrints::Utils::require_if_exists("MARC::Record");
	unless ( $rc )
	{
		$self->{visible} = "";
		$self->{error} = "Failed to load required module MARC::Record";
	}

	return $self;
}

sub output_dataobj
{
	my ($plugin, $eprint) = @_;

	my $record = MARC::Record -> new ();
	my $session = $plugin->{session};
	# From marc.pl
	my %master_degree = %{$session->get_repository->get_conf("marc")->{master_degree}};
	my %doc_degree = %{$session->get_repository->get_conf("marc")->{doc_degree}};
	my %call050 = %{$session->get_repository->get_conf("marc")->{marc050}};
	my %call090 = %{$session->get_repository->get_conf("marc")->{marc090}};
	my %ex_call050 = %{$session->get_repository->get_conf("marc")->{ex_marc050}};
	my %ex_call090 = %{$session->get_repository->get_conf("marc")->{ex_marc090}};
	
	#LDR field
	my $leader = generate_leader($eprint);
	$record->leader($leader);
	
	#00/006 Form of material
	my $field_006_value = generate_006_field($plugin, $eprint);
	my $field_006 = MARC::Field->new('006', $field_006_value);
	$record->append_fields($field_006);
	
	#007
	my $field_007_value = generate_007_field($plugin, $eprint);
	my $field_007 = MARC::Field->new('007', $field_007_value);
	$record->append_fields($field_007);
	
	#008
	my $field_008_value = generate_008_field($plugin, $eprint);
	my $field_008 = MARC::Field->new('008', $field_008_value);
	$record->append_fields($field_008);
	
	#040 cataloging source	
	#MODIFY THIS WITH YOUR OWN INSTITUTIONAL IDENTIFIER
	my $field_040 = MARC::Field->new(
				'040', '', '',
				'a' => "CaQMG",
				'b' => "eng",
				'c' => "CaQMG",
				);
	

	$record->append_fields($field_040);
	
	#042 keep empty
	#$a - Authentication code (R)
	my $field_42 = MARC::Field->new(
						'042', '', '',
						'a' => ''
						);
	$record->append_fields($field_42);

	#050
	#090
	my $divisions = marc_get_divisions($plugin, $eprint);
	my $div;
	if($divisions)
	{
		$div = $divisions->[0];
	}
	
	my $degree_name = $eprint->get_value("thesis_degree_name");
	
	#050
	my $field_050;
	if($div ne "Creative Arts Therapies")
	{
		$field_050 = MARC::Field->new(
				'050', '', '4',
				'a' => 'LE3.C66'
			);
	}
	else
	{
		$field_050 = MARC::Field->new(
				'050', '', '4',
				'a' => 'RC489.A7'
			);
	}

	my $convocation_year = "";
	if($eprint->exists_and_set("convocation_date_year"))
	{
		$convocation_year = " ".$eprint->get_value("convocation_date_year");
	}
	
	my $program = marc_get_value($eprint, "department");
	
	if ($program)
	{
		if(exists $ex_call050{$program->[0]})
		{
			my $dep_call_num = $ex_call050{$program->[0]}."$convocation_year";
			$field_050->add_subfields('b' => $dep_call_num);
		}
		elsif(exists $call050{$div})
		{
			if(exists $master_degree{$degree_name})
			{
				my $dep_call_num = $call050{$div}{'masters'}."$convocation_year";
				$field_050->add_subfields('b' => $dep_call_num);
			}
			elsif(exists $doc_degree{$degree_name})
			{
				my $dep_call_num = $call050{$div}{'phd'}."$convocation_year";
				$field_050->add_subfields('b' => $dep_call_num);
			}
		}
	}
	$record->append_fields($field_050);
	
	#090
	if ($program)
	{
		if(exists $ex_call090{$program->[0]})
		{
			my $dep_call_num = $ex_call090{$program->[0]}."$convocation_year";
			#$field_090->add_subfields('b' => $dep_call_num);
			
			my $field_090 = MARC::Field->new(
				'090', '', '',
				'a' => $dep_call_num
			);
			$record->append_fields($field_090);
		}
		elsif(exists $call090{$div})
		{	
			if(exists $master_degree{$degree_name})
			{
				my $local_call_num = $call090{$div}{'masters'}."$convocation_year";
				my $field_090 = MARC::Field->new(
					'090', '', '',
					'a' => $local_call_num
				);
				$record->append_fields($field_090);
			}
			elsif(exists $doc_degree{$degree_name})
			{
				my $local_call_num = $call090{$div}{'phd'}."$convocation_year";
				my $field_090 = MARC::Field->new(
					'090', '', '',
					'a' => $local_call_num
				);
				$record->append_fields($field_090);
			}
		}
	}

	
	#100a creators
	#Not repeatable, pick the first one if multi creators.
	my $creators = marc_get_value($eprint, "creators_name");
	if($creators)
	{
		my $field = MARC::Field->new(
			100, '1', '',
			'a' => EPrints::Utils::make_name_string($creators->[0])
			);
		$record->append_fields($field);
	}
	
	######
	#245
	######
	my $indicator_245_1 = 0;
	my $indicator_245_2 = 0;
	
	#if there is one 1XX field, for now only 100 field.
	if($record->field('100'))
	{
		$indicator_245_1 = 1;
	}
	
	#245a title
	#Not repeatable.
	my $a245 = marc_get_value($eprint, "title");
	my @arr_245;
	if($a245)
	{
		my $title = $a245->[0];
		if($title =~ m/^(the\s+|an\s+|a\s+)/i)
		{
			$indicator_245_2 = length($1);
		}
		if($title =~ m/([^:]+)\s*:\s*(.*)/)
		{
			my $sub_a = $1;
			#$sub_a =~ s/^(\s+)//;
			my $sub_b = $2;
			#$sub_b =~ s/^(\s+)//;
			my $field = MARC::Field->new(
				245, "$indicator_245_1", "$indicator_245_2",
				'a' => $sub_a,
				'h' => "[electronic resource]"." :",
				'b' => $sub_b,
				);
			$record->append_fields($field);
		}
		else
		{
			my $field = MARC::Field->new(
				245, "$indicator_245_1", "$indicator_245_2",
				'a' => $title,
				'h' => "[electronic resource]",
				);
			$record->append_fields($field);
		}
	}
	#245c creators
	#Not repeatable
	if($creators)
	{
		if($record->field('245'))
		{
			#the return value of subfields() is a list of list reference.
			my @subfields = $record->field('245')->subfields();
			#pop the last subfield to add trailing '/' which is required by subfield c.
			my @sub_before_c = @{pop(@subfields)};
			my $sub_filed_data = pop(@sub_before_c)." /";
			my $sub_field = pop(@sub_before_c);
			$record->field('245')->update($sub_field => $sub_filed_data);
			
			$record->field('245')->add_subfields('c' => EPrints::Utils::make_name_string($creators->[0], 1));
		}
		else
		{
			my $field = MARC::Field->new( 
				245, "$indicator_245_1", '',
				'c' => EPrints::Utils::make_name_string($creators->[0], 1)
				);
			$record->append_fields($field);
		}
	}
	
	######
	#260
	#MODIFY THIS WITH YOUR OWN INSTITUTION
	######
	my $field_260 = MARC::Field->new( 
			260, '', '',
			'a' => "[Montréal, Québec :",
			'b' => "Concordia University,"
			);
	
	#260c live date
	#Repeatable
	my $c260 = marc_get_value($eprint, "datestamp");
	if($c260)
	{
		foreach my $date(@{$c260})
		{
			my $year = substr $date, 0, 4;
			$field_260->add_subfields('c' => $year."]");
		}
	}
	$record->append_fields($field_260);	
	
	#300
	my $a300 = marc_get_value($eprint, "pages");
	my $field_300 = MARC::Field->new(
		300, '', '',
		'a' => "1 online resource (* p.) :",
		'b' => "ill",
	);
	$record->append_fields($field_300);
	
	######
	#502
	######
	
	#thesis_degree_name 502b
	#Not repeatable
	my $b502 = marc_get_value($eprint, "thesis_degree_name");
	if($b502)
	{
		my $thesis_degree_name = $b502->[0];
		my $field = MARC::Field->new( 
			502, '', '',
			'b' => $thesis_degree_name
			);
		$record->append_fields($field);
	}
	
	#divisions 502c
	#Not repeatable
	#MODIFY FOR YOUR OWN INSTITUTION
	if($divisions)
	{
		if($record->field('502'))
		{
			$record->field('502')->add_subfields('c' => name_division($divisions->[0]).", Concordia University");
		}
		else
		{
			my $field = MARC::Field->new(
				502, '', '',
				'c' => name_division($divisions->[0]).", Concordia University"
			);
			$record->append_fields($field);
		}
	}
	
	#502d convocation year
	#Not repeatable
	my $d502 = marc_get_value($eprint, "convocation_date");
	if($d502)
	{
		my $date = ${$d502->[0]}{'year'};		
		if($record->field('502'))
		{
			$record->field('502')->add_subfields('d' => $date);
		}
		else
		{
			my $field = MARC::Field->new(
				502, '', '',
				'd' => $date
			);
			$record->append_fields($field);
		}	
	}
	
	#504a bibliography
	#Not repeatable
	my $field_504 = MARC::Field->new( 
			504, '', '',
			'a' => "Includes bibliographical references (p. *-*)"
			);
	$record->append_fields($field_504);
	
	#abstract 520a
	#Not repeatable
	my $a520 = marc_get_value($eprint, "abstract");
	if($a520)
	{
		my $abstract = $a520->[0];
		my $field = MARC::Field->new( 
				520, '3', '',
				'a' => $abstract
				);
		$record->append_fields($field);
	}
	
	#595
	#Date made live in Spectrum
	my $a595 = marc_get_value($eprint, "datestamp");
	if($a595)
	{
		my $live_date = $a595->[0];
		$live_date = substr $live_date, 0, 10;
		my @remove_dash = split(/-/, $live_date);
		$live_date = join("", @remove_dash);
		my $field = MARC::Field->new( 
				595 , '', '',
				'a' => "Date made live in Spectrum: ".$live_date
			);
		$record->append_fields($field);
	}
	#595
	#Program
	my $ex_a595 = marc_get_value($eprint, "department");
	if($ex_a595)
	{
		my $program = $ex_a595->[0];
		my $field = MARC::Field->new( 
				595 , '', '',
				'a' => "Program: ".$program
			);
		$record->append_fields($field);
	}
	
	#thesis_advisor 599a
	#Repeatable
	my $a599 = marc_get_value($eprint, "thesis_advisors_name");
	if($a599)
	{
		my $advisors = $a599;
		foreach my $advisor(@{$advisors})
		{
			my $field = MARC::Field->new(
				599, '', '',
				'a' => EPrints::Utils::make_name_string($advisor)
				);
			$record->append_fields($field);
		}
	}
	
	#710 Added Entry-Corporate Name
	#Repeatable
	
	#710a
	#Not repeatable
	my $field_710 = MARC::Field->new( 
					710, '2', '',
					'a' => "Concordia University."
				);
	#710t
	#Not repeatable
	my $t710 = marc_get_value($eprint, "thesis_degree_name");
	if($t710)
	{
		my $degree;
		if($t710->[0] =~ m/^Theses/)
		{
			$degree = $t710->[0];
		}
		else
		{
			$degree = "Theses (".$t710->[0].")";
		}
		$field_710->add_subfields('t' => $degree);
		$record->append_fields($field_710);
	}
	
	#710b
	#Repeatable
	#MODIFY FOR YOUR OWN INSTITUTION
	if($divisions)
	{
		my $field_710_clone = $field_710->clone;
		foreach my $division(@{$divisions})
		{
			$field_710_clone->add_subfields('b' => name_division($division).".");
			if(name_division($division) eq "Mel Hoppenheim School of Cinema"
				or name_division($division) eq "John Molson School of Business")
			{
				$field_710_clone->delete_subfield(code => 'a');
				$field_710_clone->add_subfields('a' => name_division($division).".");
				$field_710_clone->delete_subfield(code => 'b');
			}
		}
		
		if($field_710_clone->subfield('t'))
		{
			$field_710_clone->delete_subfield(code => 't');
			my $degree;
			if($t710->[0] =~ m/^Theses/)
			{
				$degree = $t710->[0];
			}
			else
			{
				$degree = "Theses (".$t710->[0].")";
			}
			$field_710_clone->add_subfields('t' => $degree);
		}
		
		$record->append_fields($field_710_clone);
	}
	
	#856u Uniform Resource Identifier
	#Repeatable
	{
		my $url_856u = $eprint->get_url;
		my $field = MARC::Field->new( 
						856, '4', '0',
						'u' => $url_856u,
						'z' => "View this document",
						);
		$record->append_fields($field);
	}
	
	
	
	#983
		#MODIFY FOR YOUR OWN INSTITUTION
	if ($eprint->exists_and_set("type") && $eprint->get_value("type") eq "thesis")
	{
		my $field = MARC::Field->new( 
						983, '1', '0',
						'a' => "Concordia Theses, Research Papers, etc"
					);
		$record->append_fields($field);
	}
	
	my ($reclen, $baseaddr) = update_leader_length($record);
	$record->set_leader_lengths($reclen, $baseaddr);
	
	return \$record;

}

sub generate_leader
{
	my ($eprint) = @_;
	my @arrleader;
	
	#00-04 Record length
	my @record_lenght = qw/0 0 0 0 0/;
	
	#05 - Record length (a, c, d, n, p)
	#(a, d, p) have not been taken into consideration for now
	my $record_status_05 = "n";
	
	#06 - Type of record (a, c, d, e, f, g, i, j, k, m, o, p, r, t)
	my $record_type_06 = "a";
	
	#07 - Bibliographic level (a, b, c, d, i, m, s)
	my $bibl_level_07 = "m";
	
	#08 - Type of control (#, a)
	my $control_type_08 = " ";
	
	#09 - Character coding scheme (#, a)
	my $char_coding_09 = "a";
	###
	
	#10 - Indicator count
	my $indicator_count_10 = "2";
	
	#11 - Subfield code count
	my $subfield_count_11 = "2";
	
	#12-16 Base address of data
	my @base_address = qw/0 0 0 0 0/;
	
	#17 - Encoding level (#, 1, 2, 3, 4, 5, 7, 8, u, z)
	my $encoding_level_17 = " ";
	
	#18 Descriptive cataloging form (#, a, i, u)
	#my $catalog_form_18 = "u";
	my $catalog_form_18 = "a";
	
	#19 - Multipart resource record level (#, a, b, c)
	my $res_form_19 = " ";
	
	#20 - Length of the length-of-field portion
	my $length_field_20 = 4;
	
	#21 - Length of the starting-character-position portion
	my $start_position_21 = 5;
	
	#22 - Length of the implementation-defined portion
	my $imp_defined_22 = 0;
	
	#23 - Undefined
	my $undefined_23 = 0;
	
	@arrleader = (	@record_lenght,
					$record_status_05,
					$record_type_06,
					$bibl_level_07,
					$control_type_08,
					$char_coding_09,
					$indicator_count_10,
					$subfield_count_11,
					@base_address,
					$encoding_level_17,
					$catalog_form_18,
					$res_form_19,
					$length_field_20,
					$start_position_21,
					$imp_defined_22,
					$undefined_23
	);
	
	my $strleader = join("", @arrleader);
	return $strleader;
}

sub generate_006_field
{
	#my ($plugin, $eprint) = @_;
	
	my @arr006;
	
	@arr006 = ("m", " ", " ", " ", " ", " ", "o", " ", " ", "d", " ", " ", " ", " ", " ", " ", " ", " ");
	
	my $str006 = join("", @arr006);
	
	return $str006;
}

sub generate_007_field
{
	my ($plugin, $eprint) = @_;
	
	my @arr007;
	
	if($eprint->exists_and_set("type"))
	{
		@arr007 = ("c", "r", " ", "|", "n", " ", "|", "|", "|", "|", "|", "|", "|", "|");
	}
	else
	{
		@arr007 = ("z", "z");
	}
	
	my $str007 = join("", @arr007);
	
	return $str007;
}

sub generate_008_field
{
	my ($plugin, $eprint) = @_;
	
	my @arr008;
	
	#00-05 Export Date, yymmdd
	my @date_00;
	my ($second, $minute, $hour, $dayOfMonth, $monthOffset, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my $year = (1900 + $yearOffset) % 100;
	my $month = $monthOffset + 1;
	if($year < 10)
	{
		push(@date_00, 0);
	}
	push(@date_00, split(//, $year));
	
	if($month < 10)
	{
		push(@date_00, 0);
	}
	push(@date_00, split(//, $month));
	
	if($dayOfMonth < 10)
	{
		push(@date_00, 0);
	}
	push(@date_00, split(//, $dayOfMonth));
	
	#06 Type of date/Publication status
	my $type_date_06;
	$type_date_06 = "s";
	
	#07-10 Date 1, yyyy, live year
	my @date_1_07;
	if($eprint->exists_and_set("datestamp"))
	{
		my $date = $eprint->get_value("datestamp");
		$date = substr $date, 0, 4;
		@date_1_07 = split(//, $date);
	}
	else
	{
		@date_1_07 = (" ", " ", " ", " ");
	}
	
	#11-14 Date 2
	my @date_2_11;
	@date_2_11 = (" ", " ", " ", " ");
	
	#15-17 Place of publication, production, or execution
	my @place_pub_15;
	@place_pub_15 = ("q", "u", "c");
	
	#18-34 depends on what kind of material the eprint is, can be either:
	#Books, Computer Files, Maps, Music, Continuing Resources, Visual Materials, Mixed Materials.
	#For now, MARC solely works for thesis, so we set it as 'Books'.
	
	#18-21 Illustrations (a)
	my @illustrations_18;
	@illustrations_18 = ("a", " ", " ", " ");
	
	#22 Target audience
	my $target_aud_22;
	$target_aud_22 = " ";
	
	#23 Form of item
	my $form_item_23;
	$form_item_23 = "o";
	
	#24-27 Nature of contents (bm)
	my @nature_content_24;
	@nature_content_24 = ("b", "m", " ", " ");
	
	#28 Government publication
	my $gov_pub_28;
	$gov_pub_28 = " ";
	
	#29 Conference publication
	my $con_pub_29;
	$con_pub_29 = "0";
	
	#30 Festschrift
	my $festschrift_30;
	$festschrift_30 = "0";
	
	#31 Index
	my $index_31;
	$index_31 = "0";
	
	#32 Undefined
	my $undefined_32;
	$undefined_32 = " ";
	
	#33 Literary form
	my $literary_form_33;
	$literary_form_33 = "0";
	
	#34 Biography
	my $biography_34;
	$biography_34 = " ";

	#35-37 Language
	my @language_35;
	my @languages = marc_get_language($plugin, $eprint);
	if(scalar @languages != 0)
	{
		my $lang = $languages[0];
		@language_35 = split(//, $lang);
	}
	else
	{
		@language_35 = ("e", "n", "g");
	}

	#38 Modified record
	my $mod_record_38;
	$mod_record_38 = " ";
	
	#39 Cataloging source
	my $Catalog_source_39;
	$Catalog_source_39 = "d";
	
	@arr008 = (
		@date_00,
		$type_date_06,
		@date_1_07,
		@date_2_11,
		@place_pub_15,
		@illustrations_18,
		$target_aud_22,
		$form_item_23,
		@nature_content_24,
		$gov_pub_28,
		$con_pub_29,
		$festschrift_30,
		$index_31,
		$undefined_32,
		$literary_form_33,
		$biography_34,
		@language_35,
		$mod_record_38,
		$Catalog_source_39
	);
	
	my $str008 = join("", @arr008);
	
	return $str008;
}

#Get eprint field value.
#Since eprint field can be either 'single' or 'multiple', we create a new fuction here to unify the return value as an array.
#So the only difference is how many items in the array but not the type of the field.
sub marc_get_value
{
	my ($eprint, $field) = @_;
	
	if(!$eprint->exists_and_set($field))
	{
		return 0;
	}
	
	my @arr_value;
	my $value = $eprint->get_value($field);
	
	my $dataset = $eprint->get_dataset;
	if($dataset->get_field($field)->get_property("multiple"))
	{
		foreach my $val(@{$value})
		{
			push(@arr_value, $val);
		}
	}
	else
	{
		push(@arr_value, $value);
	}
	
	return \@arr_value;
}

sub marc_get_language
{
	my ($plugin, $eprint) = @_;
	
	my @languages;
	my %marc_language_code = %{$plugin->{session}->get_repository->get_conf("marc")->{marc_language_code}};
	
	my @documents = $eprint->get_all_documents();
	foreach my $document(@documents)
	{
		if($document->get_main() eq "preview.png")
		{
			next;
		}
		
		my $lang = $document->get_value("language");
		if(exists $marc_language_code{$lang})
		{
			$lang = $marc_language_code{$lang};
		}
		else
		{
			$lang = "eng";
		}
		push (@languages, $lang);
	}

	return @languages;
}

sub marc_get_divisions
{
	my ($plugin, $eprint) = @_;
	
	if(!$eprint->exists_and_set("divisions"))
	{
		return 0;
	}
	
	my @divisions;
	my $division = $eprint->get_value("divisions");
	
	my $dataset = $eprint->get_dataset;
	if($dataset->get_field("divisions")->get_property("multiple"))
	{
		foreach my $val(@{$division})
		{
			my $subject = EPrints::DataObj::Subject->new($plugin->{session}, $val);
			my $division_name = EPrints::Utils::tree_to_utf8($subject->render_description());
			push(@divisions, $division_name);
		}
	}
	else
	{
			my $subject = EPrints::DataObj::Subject->new($plugin->{session}, $division);
			my $division_name = EPrints::Utils::tree_to_utf8($subject->render_description());
			push(@divisions, $division_name);
	}
	
	return \@divisions;
}

#This method shuold be lasted called to create a MARC Record to set:
#00-04/leader with the length of the record,
#12-16/leader with base address of data, the sum of the lengths of the leader and the directory.
sub update_leader_length
{
	my $marc = shift;
	
	my $reclen;
	my $baseaddr = LEADER_LEN;
	
	my $dataend = 0;
	
	for my $field($marc->fields())
	{
		my $str = $field->as_usmarc;
		my $len = bytes::length($str);
		
		$dataend += $len;
		$baseaddr += DIRECTORY_ENTRY_LEN;
	}
	
	$baseaddr += 1;
	
	$reclen = $baseaddr + $dataend + 1;
	
	return ($reclen, $baseaddr);
}

#The department name be used in 502c, 710b.
	#MODIFY FOR YOUR OWN INSTITUTION
sub name_division
{
	my $division = shift;
	my $name;
	
	if($division eq "Concordia Institute for Information Systems Engineering"
		or $division eq "John Molson School of Business"
		or $division eq "Mel Hoppenheim School of Cinema"
		or $division eq "School of Graduate Studies")
	{
		$name = $division;
	}
	elsif($division eq "Accountancy"
		or $division eq "Decision Sciences and Management Information Systems"
		or $division eq "Finance"
		or $division eq "Management"
		or $division eq "Marketing")
	{
		$name = "John Molson School of Business";
	}
	elsif($division eq "Études françaises")
	{
		$name = "Département d'études françaises";
	}
	else
	{
		$name = "Dept. of ".$division;
	}
	
	return $name;
}

1;
