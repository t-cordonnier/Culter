#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/cscy'
require 'culter/csey'

require './test-function.rb'

$CULTER_VERBOSE = 5

line = "Sample segment (Sample parenthesis. Contains two phrases) ended. Segment two."

culter = Culter::CSC::YML::CscyDocument.new "#{File.dirname(__FILE__)}/../samples/sample.cscy"
test "no protected parts", culter.segmenter('en').cut(line), [
	"Sample segment (Sample parenthesis.",			# no protection		# Exception for Mrs.
	" Contains two phrases) ended.",
	" Segment two."
]

culter = Culter::CSE::YML::CseyDocument.new "#{File.dirname(__FILE__)}/../samples/sample.csey"
test "with protected parts", culter.segmenter('en').cut(line), [
	"Sample segment (Sample parenthesis. Contains two phrases) ended.",		# protection works!
	" Segment two."
]
