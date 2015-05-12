# MARC Import/Export Plugins Configuration
# (C) 2010 Bin Han <bin.han@concordia.ca>
# (C) 2009 Tomasz Neugeabuer <tomasz.neugebauer@concordia.ca>
# (C) 2008 Jose Miguel Parrella Romero <bureado@cpan.org>

# Shall this plugin import subjects from your MARC records?
# You have to create the subjects before loading them

#
# Plugin EPrints::Plugin::Import::MARC
#

# MARC tofro EPrints Mappings
# These mappings were made together with Aile Filippi <aile@biblio.com.ve>
# Do _not_ add compound mappings here.

$c->{marc}->{marc2ep} = { # MARC to EPrints


	'020a' => 'isbn',
	'020z' => 'isbn',	# Include invalid ISBN for the sake of better search results.
	'022a' => 'issn',
#	'047a' => 'composition_type',
#	'111a' => 'event_title',
#	'111c' => 'event_location',
#	'111d' => 'event_dates',
	'245a' => 'title',
	'245b' => 'subtitle',
	'250a' => 'edition',
#	'246a' => 'book_title',
	'260a' => 'place_of_pub',
	'260b' => 'publisher',
	'260c' => 'date',
#  	'300' => 'pages_aacr',
	'362a' => 'volume',
	'440a' => 'series',
	'440c' => 'volume',
	'440x' => 'issn',
#	'500a' => 'note',
	'520a' => 'abstract',
#	'650a' => 'subjects',
#	'653a' => 'keywords',
#	'710a' => 'institution',
#	'711a' => 'event_type',
	'730a' => 'publication',
#  	'856u' => 'related_url',

};

$c->{marc}->{marc2ep}->{constants} = { # MARC to EPrints constant values

#	'note' => 'Imported by  EPrints::Plugin::Import::MARC',

};


######################################################################
#
# Plugin-specific settings.
#
# Any non empty hash set for a specific plugin will override the
# general one above!
#
######################################################################


# TN
#
# Plugin EPrints::Plugin::Import::MARC::ConcordiaTheses
#
$c->{marc}->{'EPrints::Plugin::Import::MARC::ConcordiaTheses'}->{marc2ep} = {

	'020a' => 'isbn',
	'020z' => 'isbn',	# Include invalid ISBN for the sake of better search results.
	'022a' => 'issn',
  #'245a' => 'title',
	'250a' => 'edition',
	'260a' => 'place_of_pub',
	'260b' => 'publisher',
	'260c' => 'date',
  '300a' => 'pages_aacr',
	'362a' => 'volume',
	'440a' => 'series',
	'440c' => 'volume',
	'440x' => 'issn',
#	'500a' => 'note',
	'520a' => 'abstract',
#	'650a' => 'subjects',
#	'653a' => 'keywords',
#	'710a' => 'institution',
#	'711a' => 'event_type',
	'730a' => 'publication',
# '856u' => 'related_url',
#	'009' => 'pq_id',
#	'710t' => 'thesis_degree_name',
#	'710b' => 'department',

};

$c->{marc}->{'EPrints::Plugin::Import::MARC::ConcordiaTheses'}->{constants} = { # MARC to EPrints constants

  'type' => 'thesis',
# 'note' => 'Imported by  EPrints::Plugin::Import::MARC::ConcordiaTheses',
  'institution' => 'Concordia University',
  'date_type' => 'submitted',
};

# end of TN


##################
#EPrints to MARC
##################

$c->{marc}->{ep2marc} = { # EPrints to MARC

	creators_name => '100a',
	corp_creators => '110a',
	title => '245a',
	subjects => '650a',
	keywords => '653a',
	abstract => '520a',
	note => '500a',
	date => '260c',
	series => '440a',
	publication => '730a',
	volume => '362a',
	number => '362a',
	publisher => '260b',
	place_of_pub => '260a',
	pagerange => '300a',
	pages => '300a',
  pages_aacr => '300a',
	event_title => '111a',
	event_location => '111c',
	event_dates => '111d',
	event_type => '711a',
	institution => '710a',
	isbn => '020a',
	issn => '022a',
	book_title => '246a',
	editors => '700a',
	official_url => '856u',
	related_url => '856u',
	output_media => '533a',
	exhibitors => '700a',
	num_pieces => '300a',
	composition_type => '047a',
	producers => '700a',
	conductors => '700a',
	lyricists => '700a',

};

	#MODIFY THIS WITH YOUR OWN INSTITUTION REPOID
$c->{marc}->{ep2marc}->{constants} = { # EPrints to MARC constant values

	repository => 'repoID',
};


##################
#<MARC Export>
#Bin Han
#Aug, 2010
#MODIFY THIS FOR YOUR OWN INSTITUTION##################

$c->{marc}->{marc050} = {
	'Biology' => {
		'masters' => 'B56M',
		'phd'=> 'B56P',
	},
	'Chemistry and Biochemistry' => {
		'masters' => 'C54M',
		'phd' => 'C54P',
	},
	'Classics, Modern Languages and Linguistics' => {
		'masters' => 'C58M',
	},
	'Communication Studies' => {
		'masters' => 'C66M',
		'phd' => 'C66P',
	},
	'Creative Arts Therapies' => {
		'masters' => 'C6',
	},
	'Economics' => {
		'phd' => 'E26P',
	},
	'Education' => {
		'masters' => 'E38M',
		'phd' => 'E38P',
	},
	'English' => {
		'masters' => 'E54M',
	},
	'Études françaises' => {
		'masters' => 'F73M',
	},
	'Exercise Science' => {
		'masters' => 'E94M',
	},
	'Geography, Planning and Environment' => {
		'masters' => 'G46M',
	},
	'History' => {
		'masters' => 'H57M',
		'phd' => 'H57P',
	},
	'Journalism' => {
		'masters' => 'J68M',
	},
	'Mathematics and Statistics' => {
		'masters' => 'M38M',
		'phd' => 'M38P',
	},
	'Philosophy' => {
		'masters' => 'P45M',
	},
	'Physics' => {
		'masters' => 'P49M',
		'phd' => 'P49P',
	},
	'Political Science' => {
		'masters' => 'P65M',
		'phd' => 'P65P',
	},
	'Psychology' => {
		'masters' => 'P79M',
		'phd' => 'P79P',
	},
	'Religion' => {
		'masters' => 'R45M',
		'phd' => 'R45P',
	},
	'Sociology and Anthropology' => {
		'masters' => 'S63M',
		'phd' => 'S63P',
	},
	'Theological Studies' => {
		'masters' => 'T44M',
	},
	'Building, Civil and Environmental Engineering' => {
		'masters' => 'B85M',
		'phd' => 'B85P',
	},
	'Computer Science and Software Engineering' => {
		'masters' => 'C67M',
		'phd' => 'C67P',
	},
	'Electrical and Computer Engineering' => {
		'masters' => 'E44M',
		'phd' => 'E44P',
	},
	'Mechanical and Industrial Engineering' => {
		'masters' => 'M43M',
		'phd' => 'M43P',
	},
	'Art Education' => {
		'masters' => 'A33M',
		'phd' => 'A33P',
	},
	'Art History' => {
		'masters' => 'A35M',
		'phd' => 'A35P',
	},
	'Mel Hoppenheim School of Cinema' => {
		'masters' => 'M45M',
		'phd' => 'M45P',
	},
	'School of Graduate Studies' => {
		'masters' => 'S36M',
		'phd' => 'S36P',
	},
};

$c->{marc}->{marc090} = {
	'Biology' => {
		'masters' => 'LE 3 C66B56M',
		'phd'=> 'LE 3 C66B56P',
	},
	'Chemistry and Biochemistry' => {
		'masters' => 'LE 3 C66C54M',
		'phd' => 'LE 3 C66C54P',
	},
	'Classics, Modern Languages and Linguistics' => {
		'masters' => 'LE 3 C66C58M',
	},
	'Communication Studies' => {
		'masters' => 'LE 3 C66C66M',
		'phd' => 'LE 3 C66C66P',
	},
	'Creative Arts Therapies' => {
		'masters' => 'RC 489 A7C6+',
	},
	'Economics' => {
		'phd' => 'LE 3 C66E26P',
	},
	'Education' => {
		'masters' => 'LE 3 C66E38M',
		'phd' => 'LE 3 C66E38P',
	},
	'English' => {
		'masters' => 'LE 3 C66E54M',
	},
	'Études françaises' => {
		'masters' => 'LE 3 C66F73M',
	},
	'Exercise Science' => {
		'masters' => 'LE 3 C66E94M',
	},
	'Geography, Planning and Environment' => {
		'masters' => 'LE 3 C66G46M',
	},
	'History' => {
		'masters' => 'LE 3 C66H57M',
		'phd' => 'LE 3 C66H57P',
	},
	'Journalism' => {
		'masters' => 'LE 3 C66J68M',
	},
	'Mathematics and Statistics' => {
		'masters' => 'LE 3 C66M38M',
		'phd' => 'LE 3 C66M38P',
	},
	'Philosophy' => {
		'masters' => 'LE 3 C66P45M',
	},
	'Physics' => {
		'masters' => 'LE 3 C66P49M',
		'phd' => 'LE 3 C66P49P',
	},
	'Political Science' => {
		'masters' => 'LE 3 C66P65M',
		'phd' => 'LE 3 C66P65P',
	},
	'Psychology' => {
		'masters' => 'LE 3 C66P79M',
		'phd' => 'LE 3 C66P79P',
	},
	'Religion' => {
		'masters' => 'LE 3 C66R45M',
		'phd' => 'LE 3 C66R45P',
	},
	'Sociology and Anthropology' => {
		'masters' => 'LE 3 C66S63M',
		'phd' => 'LE 3 C66S63P',
	},
	'Theological Studies' => {
		'masters' => 'LE 3 C66T44M',
	},
	'Building, Civil and Environmental Engineering' => {
		'masters' => 'LE 3 C66B85M',
		'phd' => 'LE 3 C66B85P',
	},
	'Computer Science and Software Engineering' => {
		'masters' => 'LE 3 C66C67M',
		'phd' => 'LE 3 C66C67P',
	},
	'Electrical and Computer Engineering' => {
		'masters' => 'LE 3 C66E44M',
		'phd' => 'LE 3 C66E44P',
	},
	'Mechanical and Industrial Engineering' => {
		'masters' => 'LE 3 C66M43M',
		'phd' => 'LE 3 C66M43P',
	},
	'Art Education' => {
		'masters' => 'LE 3 C66A33M',
		'phd' => 'LE 3 C66A33P',
	},
	'Art History' => {
		'masters' => 'LE 3 C66A35M',
		'phd' => 'LE 3 C66A35P',
	},
	'Mel Hoppenheim School of Cinema' => {
		'masters' => 'LE 3 C66M45M',
		'phd' => 'LE 3 C66M45P',
	},
	'School of Graduate Studies' => {
		'masters' => 'LE 3 C66S36M',
		'phd' => 'LE 3 C66S36P',
	},
};

#add new language code when you edit /cfg/namedsets/languages
$c->{marc}->{marc_language_code} = {
	'en' => 'eng',	#english
	'fr' => 'fre',	#french
	'da' => 'dan',	#danish
	'de' => 'ger',	#german
	'el' => 'grc',	#greek
	'it' => 'ita',	#italian
	'nl' => 'dut',	#dutch
	'no' => 'nor',	#norwegian
	'pl' => 'pol',	#polish
	'pt' => 'por',	#portuguese
	'ru' => 'rus',	#russian
	'es' => 'spa',	#spanish
	'sv' => 'swe'	#swedish
};

#existing master degree
$c->{marc}->{master_degree} = {
	'Theses (M.A.)' => '',
	'Theses (M.Comp.Sc.)' => '',
	'Theses (M.F.A.)' => '',
	'Theses (M.Eng.)' => '',
	'Theses (M.Sc.)' => '',
	'Theses (M.T.M.)' => '',
	'Theses (M.A.Sc.)' => '',
	'Theses (M.Sc.Admin.)' => '',
	'Theses (M.A>)' => '',
	'Theses (M. Sc.)' => '',
	'Theses (M.A)' => '',
	'Theses (M.Comp Sc.)' => '',
	'Theses (M.Sc.Admin)' => '',
	'Master in the Teaching of Mathematics' => '',
	'M.A.' => '',
	'M. Sc.' => '',
	'M.A. Sc.' => '',
	'Research papers (M.A.)' => '',
	'Projects (M.Sc.)' => '',
	'Master in the Teaching of Mathematics' => '',
	'Major reports (M.Comp.Sc.)' => '',
	'Major reports (M.Comp.Sc)' => '',
	'Master of Arts' => '',
	'Master of Computer Science' => '',
	'M. Comp. Sc.' => '',
	'M.Sc.' => '',
	'Masters of Arts' => '',
	'Master of Science' => '',
	'Masters of Science' => '',
	'M.Sc. Geography, Urban and Environmental Studies' => '',
	'Master' => '',
	'Master of Arts (Art Education)' => '',
	'Master of Applied Science' => '',
	'Master of Applied Science (Building Engineering)' => '',
	'MA' => '',
	'M.A.Sc.' => '',
	'Masters of Fine Arts' => '',
	'M.A. aaa' => '',
	'M.A.Sc' => '',
	'Master\'s Degree in Arts (Specialized Individual Program)' => '',
	'Master of applied science' => '',
	'M.A Psychology' => '',
	'Masters of Sociology' => '',
	'Master of Applied Sciences (Civil Engineering)' => '',
	'M. Sc. Finance' => '',
	'MASTER OF SCIENCE (PHYSICS' => '',
	'Degree of Master of Arts (Educational Technology)' => '',
	'M. Eng.' => '',
	'Master of Science in Administration (Finance)' => '',
	'Masters of Art' => '',
	'Master of Religious Studies (Judaic Studies)' => '',
	'Masters in Arts Social and Cultural Anthropology' => '',
	'M. Sc. Admin.' => '',
	'M.A' => '',
	'(M.A. Sc.' => '',
	'M.T.M.' => '',
	'Theses M. Comp. Sc.)' => '',
	'Theses (M.A. Sc.)' => '',
	'Theses (M. Sc. Admin.)' => '',
	'M. A.' => '',
	'M. Comp.Sc.' => '',
};

#existing doctor degree
$c->{marc}->{doc_degree} = {
	'Theses (Ph.D.)' => '',
	'Theses (Ph.D.' => '',
	'Theses (D.Eng.)' => '',
	'Ph. D.' => '',
	'Theses (PhD)' => '',
	'PhD' => '',
	'Ph. D.' => '',
	'Doctor of Philosophy' => '',
	'Ph.D.' => '',
	'Doctor of Philosophy (Humanities)' => '',
	'DOCTOR OF PHILOSOPHY (COMPUTER SCIENCE)' => '',
	'Ph.D. Humanities (Fine Arts)' => '',
	'Doctorate in Philosophy' => '',
};

#exceptions that call number based on program
$c->{marc}->{ex_marc050} = {
	'Administration (Decision Sciences and Management Information Systems option)' => 'D43M',
	'Administration (Finance option)' => 'F56M',
	'Administration (Management option)' => 'M36M',
	'Administration (Marketing option)' => 'M37M',
	'Business Administration (Accountancy specialization)' => 'A23P',
	'Business Administration (Decision Sciences and Management Information Systems specialization)' => 'D43P',
	'Business Administration (Finance specialization)' => 'F56P',
	'Business Administration (Management specialization)' => 'M36P',
	'Business Administration (Marketing specialization)' => 'M37P',
	'Information Systems Security' => 'I54M',
	'Quality Systems Engineering' => 'Q35M',
};

$c->{marc}->{ex_marc090} = {
	'Administration (Decision Sciences and Management Information Systems option)' => 'LE 3 C66D43M',
	'Administration (Finance option)' => 'LE 3 C66F56M',
	'Administration (Management option)' => 'LE 3 C66M36M',
	'Administration (Marketing option)' => 'LE 3 C66M37M',
	'Business Administration (Accountancy specialization)' => 'LE 3 C66A23P',
	'Business Administration (Decision Sciences and Management Information Systems specialization)' => 'LE 3 C66D43P',
	'Business Administration (Finance specialization)' => 'LE 3 C66F56P',
	'Business Administration (Management specialization)' => 'LE 3 C66M36P',
	'Business Administration (Marketing specialization)' => 'LE 3 C66M37P',
	'Information Systems Security' => 'LE 3 C66I54M',
	'Quality Systems Engineering' => 'LE 3 C66Q35M',
};

##################
#</MARC Export>
##################