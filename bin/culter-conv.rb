#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

$CULTER_VERBOSE = 0

if ARGV.count < 2
	puts <<"EOF"
Syntax : culter-conv.rb [options] <original file> <dest file>

Options:
	--version, -v: for SRX format, output in SRX 1.0 or 2.0
	--maprule: 	if there are multiple map rules (SRX 1 or CSC,CSE) and you want to generate SRX 2.0, select one rules
	--uncascade, --langs: 	generate a file with only given languages (space-separated), without cascading
	--verbose, --V: 	display debug messages
EOF
	exit
end

require 'culter/args'
doc = Culter::Args::load_file(ARGV.shift)

tra = ARGV.shift
if tra =~ /srx$/
	require 'getoptlong'
	version = '2.0'; langs = nil; mapruleName = nil; mode = 'machine'
	GetoptLong.new(
		[ '--verbose', '-V', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--version', '-v', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--mode', '-M', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--maprule', '--maprule-name', '-m', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--uncascade', '--langs', '-l', GetoptLong::OPTIONAL_ARGUMENT ]
	).each do |opt, arg|
		case opt
			when '--verbose' then $CULTER_VERBOSE = arg.to_i 
			when '--version' then version = arg 
			when '--uncascade' then langs = arg.split(',')
			when '--maprule' then mapruleName = arg
			when '--mode' then mode = arg
		end
	end	
	if tra == 'srx' then 
		doc.to_srx($stdout, version, langs, mapruleName, mode)
	else
		File.open(tra, 'w:UTF-8') { |f| f.puts "<?xml version='1.0' encoding='UTF-8'?>"; doc.to_srx(f, version, langs, mapruleName, mode) }
	end
elsif tra =~ /cscx$/
	require 'getoptlong'
	version = '2.0'; langs = nil; mapruleName = nil
	GetoptLong.new(
		[ '--maprule', '--maprule-name', '-m', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--uncascade', '--langs', '-l', GetoptLong::OPTIONAL_ARGUMENT ]
	).each do |opt, arg|
		case opt
			when '--uncascade' then langs = arg.split(',')
			when '--maprule' then mapruleName = arg
		end
	end	
	if tra == 'cscx' then 
		doc.to_cscx($stdout, langs, mapruleName)
	else
		File.open(tra, 'w:UTF-8') { |f| f.puts "<?xml version='1.0' encoding='UTF-8'?>"; doc.to_cscx(f, langs, mapruleName) }
	end
elsif tra =~ /cscy$/
	require 'yaml'
	
	if tra == 'cscy' then 
		$stdout.puts YAML.dump(doc.to_yaml_struct())
	else
		File.open(tra, 'w:UTF-8') { |f| f.puts YAML.dump(doc.to_yaml_struct()) }
	end

end	