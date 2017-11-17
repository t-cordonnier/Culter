#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

if ARGV.empty?
	require 'culter/simple'
	culter = Culter::Simple.new	
else
	data = ARGV.shift
    $CULTER_VERBOSE = 0; while data =~ /-(v+)/ do  $CULTER_VERBOSE = $CULTER_VERBOSE + $1.length;  data = ARGV.shift  end
	if data =~ /\.srx$/
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
	elsif data =~ /\.csc[xy]$/
		if data =~ /\.cscx$/
			require 'culter/cscx'
			doc = Culter::CSC::XML::CscxDocument.new(data)
		elsif data =~ /\.cscy$/
			require 'culter/cscy'
			doc = Culter::CSC::YML::CscyDocument.new(data)		
		end 
		
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
        if $CULTER_VERBOSE > 0 then puts "#{culter.rulesCount} rules found."; puts "#{culter.protectedPartsCount} protected parts found."; puts "Join between segments = '#{culter.joinString}'" end
	else
		require 'culter/simple'
        if $CULTER_VERBOSE > 0 then puts "Using simple segmenter" end
		culter = Culter::Simple.new	
	end
end

tab = []
while true
	line = gets
	line.gsub! /\r?\n/, ''
	if line == 'EOF' then break end
	tab << line
end

if culter.respond_to? 'join'
	puts culter.join(tab) 
else
	puts tab.join('') 

end