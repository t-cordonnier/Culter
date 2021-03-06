#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

require 'culter/args'

Culter::Args::set_verbosity!
culter = Culter::Args::get_doc
if culter.respond_to? 'segmenter'
  culter = Culter::Args::get_segmenter(culter, ARGV.shift)
end
if $CULTER_VERBOSE > 0 then 
  if culter.respond_to? 'protectedPartsCount' then puts "#{culter.protectedPartsCount} protected parts found." end
  if culter.respond_to? 'joinString' then puts "Join between segments = '#{culter.joinString}'" end
end


while line = gets
	if $CULTER_VERBOSE > 0 then
		# Help for debug: displays details
		i = 0; start = Time.new
		puts "\n\n"
		culter.cut(line) { |phrase| i = i + 1; puts "#{i} --- ", phrase }
		if $CULTER_VERBOSE > 1 then
			puts "Applied rules : \n"
			puts culter.cut_debug(line)
		end
		puts "Time : #{Time.new - start} seconds"
	else
		# Default: acts as a filter stdin->stdout
		culter.cut(line) { |phrase| puts phrase }
	end
end