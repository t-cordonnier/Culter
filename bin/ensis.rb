#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation

require 'culter/args'
require 'culter/ensis/common'

Culter::Args::set_verbosity!
culter = Culter::Args::get_doc
if ARGV.count >= 1 and culter.respond_to? 'segmenter' then
  culter = Culter::Args::get_segmenter(culter, ARGV.shift)
  Culter::Ensis::Tester.new(culter).start
else
  Culter::Ensis::Editor.new(culter).start  
end


