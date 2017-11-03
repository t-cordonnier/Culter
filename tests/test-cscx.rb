#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/cscx'

culter = Culter::CSCX::CscxDocument.new "#{File.dirname(__FILE__)}/../samples/sample.cscx"

require './test-function.rb'

line = "Here is Mrs. Untel. She came here! All fine."

# 	1. Test that this phrase segments correctly with "en" as language

test "en", culter.segmenter('en').cut(line), [
	"Here is Mrs. Untel.",			# Exception for Mrs.
	" She came here!",
	" All fine."
]

# 	2. Test that if language = "fr", abbreviations don't work but other cuts work correctly

test "fr", culter.segmenter('fr').cut(line), [
	"Here is Mrs.", " Untel.",		# Exception for Mrs. does not work (not in language 'fr')
	" She came here!",
	" All fine."
]

#	3. Test format handles

line = "Here is Mrs. <i>Untel.</i> She came here! All fine."

test "en", culter.segmenter('en').cut(line), [
	"Here is Mrs. <i>Untel.</i>",			# closing tag in the initial string
	" She came here!",
	" All fine."
]
