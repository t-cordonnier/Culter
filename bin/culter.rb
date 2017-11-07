#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

$CULTER_VERBOSE = 0 
if not(ARGV.empty?) and (ARGV[0] =~ /-v/) then 
  while ARGV[0] =~ /-(v+)/ do  $CULTER_VERBOSE = $CULTER_VERBOSE + $1.length; ARGV.shift ; end
end

if ARGV.empty?
	require 'culter/simple'
	if $CULTER_VERBOSE > 0 then puts "Using simple segmenter" end
	culter = Culter::Simple.new	
else
	data = ARGV.shift
	if data =~ /\.srx$/i
		require 'culter/srx'
		doc = Culter::SRX::SrxDocument.new(data)
		
		data = ARGV.shift
		if data =~ /^(.+):(.+)$/
			culter = doc.segmenter($2,$1)
		elsif data != nil
			culter = doc.segmenter(data)
		else
			raise ArgumentError.new("Missing language")
		end
		if $CULTER_VERBOSE > 0 then puts "#{culter.rulesCount} rules found." end
	elsif data =~ /\.cscx$/
		require 'culter/cscx'
		doc = Culter::CSCX::CscxDocument.new(data)
		
		data = ARGV.shift
		if data =~ /^(.+):(.+)$/
			culter = doc.segmenter($2,$1)
		elsif data != nil
			culter = doc.segmenter(data)
		else
			raise ArgumentError.new("Missing language")
		end
		if $CULTER_VERBOSE > 0 then puts "#{culter.rulesCount} rules found." end
	elsif data =~ /\.csex$/
		require 'culter/csex'
		doc = Culter::CSEX::CsexDocument.new(data)
		
		data = ARGV.shift
		if data =~ /^(.+):(.+)$/
			culter = doc.segmenter($2,$1)
		elsif data != nil
			culter = doc.segmenter(data)
		else
			raise ArgumentError.new("Missing language")
		end
		if $CULTER_VERBOSE > 0 then puts "#{culter.rulesCount} rules found."; puts "#{culter.protectedPartsCount} protected parts found." end
	else
		raise ArgumentError.new("#{data} is not a valid segmentation format")	
	end
end

while line = gets
	if $CULTER_VERBOSE > 0 then
		# Help for debug: displays details
		i = 0; start = Time.new
		puts "\n\n"
		culter.cut(line) { |phrase| i = i + 1; puts "#{i} --- ", phrase }
		puts "Time : #{Time.new - start} seconds"
	else
		# Default: acts as a filter stdin->stdout
		culter.cut(line) { |phrase| puts phrase }
	end
end