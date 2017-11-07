#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/simple'

$CULTER_VERBOSE = 5

require './test-function.rb'

culter = Culter::Simple.new

line = "Here is Mr. Untel. He came here. All fine."

test "test", culter.cut(line), [
	"Here is Mr.", "Untel.",			# No exception for Mr.
	"He came here.",
	"All fine."
]


