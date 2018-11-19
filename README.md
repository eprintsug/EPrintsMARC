# EPrintsMARC
MARC Import/Export Plugin as Configured at Concordia University

Loading MARC-encoded files into EPrints requires the installation of 
the import/export plugin, initially developed by Romero and Miguel (http://files.eprints.org/323/) and 
updated here by Tomasz Neugebauer and Adam Field.

The installation of this plugin requires the following two CPAN modules:
MARC::Record and MARC::File::USMARC. The MARC plugin was then 
subclassed to create an import plugin named "Concordia Theses" 
which is customized for thesis MARC records at Concordia University in Montreal.
