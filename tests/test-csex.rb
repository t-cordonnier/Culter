#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/cscx'
require 'culter/csex'

require './test-function.rb'

line = "Sample segment (Sample parenthesis. Contains two phrases) ended. Segment two."

culter = Culter::CSCX::CscxDocument.new "#{File.dirname(__FILE__)}/../samples/sample.cscx"
test "en", culter.segmenter('en').cut(line), [
	"Sample segment (Sample parenthesis.",			# no protection		# Exception for Mrs.
	" Contains two phrases) ended.",
	" Segment two."
]

culter = Culter::CSEX::CsexDocument.new "#{File.dirname(__FILE__)}/../samples/sample.csex"
test "en", culter.segmenter('en').cut(line), [
	"Sample segment (Sample parenthesis. Contains two phrases) ended.",		# protection works!
	" Segment two."
]

