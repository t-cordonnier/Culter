#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/cscx'
require 'culter/csex'

require './test-function.rb'

$CULTER_VERBOSE = 5

#	1. Basic protected parts test (once without, once with)

line = "Sample segment (Sample parenthesis. Contains two phrases) ended. Segment two."

culter = Culter::CSC::XML::CscxDocument.new "#{File.dirname(__FILE__)}/../samples/sample.cscx"
test "no protected parts", culter.segmenter('en').cut(line), [
	"Sample segment (Sample parenthesis.",			# no protection		# Exception for Mrs.
	" Contains two phrases) ended.",
	" Segment two."
]

culter = Culter::CSE::XML::CsexDocument.new "#{File.dirname(__FILE__)}/../samples/sample.csex"
test "with protected parts", culter.segmenter('en').cut(line), [
	"Sample segment (Sample parenthesis. Contains two phrases) ended.",		# protection works!
	" Segment two."
]

#	2. Recursivity test

# 2.1	use [ and ], which are recursive in sample.csex
line = "Sample segment [Sample parenthesis. Contains two phrases [and also parenthesis. with phrases] and many more. And more] ended. Segment two."
test "recursive", culter.segmenter('en').cut(line), [
	"Sample segment [Sample parenthesis. Contains two phrases [and also parenthesis. with phrases] and many more. And more] ended.",		# recursion works!
	" Segment two."
]

# 2.2	use { and }, which are not recursive in sample.csex
line = "Sample segment {Sample parenthesis. Contains two phrases {and also parenthesis. with phrases} and many more. And more} ended. Segment two."
test "non-recursive", culter.segmenter('en').cut(line), [
	"Sample segment {Sample parenthesis. Contains two phrases {and also parenthesis. with phrases} and many more.",
	" And more} ended.",		# no recursion works!
	" Segment two."
]
