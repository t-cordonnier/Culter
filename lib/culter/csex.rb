# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/cscx'
require 'culter/cse'

##
# Implement a segmenter with Culter Segmentation Extended as XML
# XML-based format with specific extensions which are NOT possible via SRX
# 
module Culter::CSE::XML

	
	class CsexCallbacks < Culter::CSC::XML::CscxCallbacks	# :nodoc: all
		attr_reader :protectedParts, :joins
		
		def initialize()
			super
            @protectedParts = {}; @joins = {}
		end
		
		def tag_start(element, attributes)
			if element == 'protected-part'
				@curProtectedParts << Culter::CSE::ProtectedPart.new(@protectedParts.count - 1, attributes['begin'], attributes['end'], 'yes' == attributes['recursive'])
			elsif element == 'languagerule'
				@curProtectedParts = []
				@protectedParts[attributes['languagerulename']] = @curProtectedParts
				@joins[attributes['languagerulename']] = attributes['join']
			elsif element == 'rule' and attributes['break'] == 'yes'    # No SRX in this case
				newRule! Culter::CSE::SuperRule.new(true, newRuleName())
				return
			elsif element == 'break-rule'     # No SRX in this case
				newRule! Culter::CSE::SuperRule.new(true, newRuleName())
				return
			elsif element == 'beforebreak' 
				if attributes['keep'] != nil then @curRule.beforeKeep = attributes['keep'] end
			elsif element == 'afterbreak' 
				if attributes['keep'] != nil then @curRule.afterKeep = attributes['keep'] end
			end
			super(element, attributes)
		end		  
	end
	
	##
	# Loads a SRX document and can apply the rules
	class CsexDocument < Culter::CSC::XML::CscxDocument
	
		def initialize(src)
			callback = CsexCallbacks.new
			load(src,'csex',callback)
			
			@cascade = callback.cascade
			@mapRules = callback.mapRules
			@defaultMapRule = callback.defaultMapRule
			@langRules = callback.langRules
			@formatHandle = callback.formatHandle
			@protectedParts = callback.protectedParts
			@joins = callback.joins
		end
		
		include Culter::CSE::SegmenterFactory
			
	end
	
end

