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
			@protectedParts = {}; @counter = 0
			super(src)
			temp = @langRules; @langRules = {}
			temp.each_pair do |name,rules| 
				@langRules[name] = rules.select { |rule0| rule0.is_a? Culter::SRX::Rule or rule0.is_a? Culter::CSC::ApplyRuleTemplate } 
				@protectedParts[name] = rules.select { |rule0| rule0.is_a? Culter::CSE::ProtectedPart }
			end
		end
		
		def extension() 'csey' end
		
	private
		
		def to_lang_rule(yaml_hash)
			if yaml_hash['type'] =~ /^protected-part/
				@counter = @counter + 1
				return Culter::CSE::ProtectedPart.new(@counter - 1, yaml_hash['begin'], yaml_hash['end'], 'yes' == yaml_hash['recursive'])
			else
				return super(yaml_hash)
			end
		end
		
	end

end

