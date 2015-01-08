#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/simple'

def test(name,result,expected)
	if result.count == expected.count then 
		puts "#{name}: Segment count OK"
		for i in 0..(result.count)
			if result[i] == expected[i] then
				puts "Segment #{i+1} OK (#{result[i]})"
			else
				puts "*** Segment #{i+1} failed: expected '#{expected[i]}', found '#{result[i]}'"
			end
		end
	else
		puts "*** #{name} failed: expected #{expected.count} segments, found #{result.count}"
		for i in 0..(result.count)
			unless result[i] == expected[i] 
				puts "*** Segment #{i+1} failed: expected '#{expected[i]}', found '#{result[i]}'"
			end
		end		
	end
end

culter = Culter::Simple.new

line = "Here is Mr. Untel. He came here. All fine."

test "test", culter.cut(line), [
	"Here is Mr.", "Untel.",			# No exception for Mr.
	"He came here.",
	"All fine."
]


