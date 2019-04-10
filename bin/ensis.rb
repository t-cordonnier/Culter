#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

require 'culter/args'

Culter::Args::set_verbosity!
culter = Culter::Args::get_doc
if culter.respond_to? 'segmenter'
  culter = Culter::Args::get_segmenter(culter, ARGV.shift)
end

require 'culter/ensis/tester'

Culter::Ensis::Tester.new(culter).start
