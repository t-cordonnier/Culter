#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

if not(ARGV.empty?) and (ARGV[0] =~ /-v/) then verbose = true; ARGV.shift end

if ARGV.empty?
	require 'culter/simple'
	if verbose then puts "Using simple segmenter" end
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
		if verbose then puts "#{culter.rulesCount} rules found." end
	else
		raise ArgumentError.new("#{data} is not a valid segmentation format")	
	end
end

while line = gets
	if verbose then
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