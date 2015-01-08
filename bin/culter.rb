#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/simple'

culter = Culter::Simple.new

while line = gets
	culter.cut(line) { |phrase| puts phrase }
end
