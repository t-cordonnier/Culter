# encoding: utf-8

require 'culter/cscy'
require 'culter/cse'
require "yaml"

##
# YAML reader for CSE
# Format with specific extensions which are NOT possible via SRX
# 
module Culter::CSE::YML

	##
	# Loads a SRX document and can apply the rules
	class CseyDocument < Culter::CSC::YML::CscyDocument
		include Culter::CSE::SegmenterFactory
	
		def initialize(src)
			@protectedParts = {}; @joins = {}; @counter = 0
			super(src)
			temp = @langRules; @langRules = {}
			temp.each_pair do |name,rules| 
				@langRules[name] = rules.select { |rule0| rule0.is_a? Culter::SRX::Rule or rule0.is_a? Culter::CSC::ApplyRuleTemplate } 
				@protectedParts[name] = rules.select { |rule0| rule0.is_a? Culter::CSE::ProtectedPart }
				rules.select { |rule0| rule0.is_a? Culter::CSE::YML::Join }.each { |join| @joins[name] = join.value }
			end
		end
		
		def extension() 'csey' end
		
	private
		
		def to_lang_rule(name, yaml_hash)
			if yaml_hash['type'] =~ /^protected-part/
				@counter = @counter + 1
				return Culter::CSE::ProtectedPart.new(@counter - 1, yaml_hash['begin'], yaml_hash['end'], 'yes' == yaml_hash['recursive'])
			elsif yaml_hash['type'] =~ /^join/
				return Culter::CSE::YML::Join.new(yaml_hash['value'])
			else
				return super(name, yaml_hash)
			end
		end
		
	end
	
	class Join
		def initialize(val) @value = val end
		attr_reader :value
	end

end

