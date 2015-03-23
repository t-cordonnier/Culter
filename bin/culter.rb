#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

if ARGV.empty?
	require 'culter/simple'
	puts "Using simple segmenter"
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
	else
		raise ArgumentError.new("#{data} is not a valid segmentation format")	
	end
end

while line = gets
	culter.cut(line) { |phrase| puts phrase }
end
