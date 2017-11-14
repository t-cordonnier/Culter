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
		attr_reader :protectedParts
		
		def initialize()
			super
            @protectedParts = {}
		end
		
		def tag_start(element, attributes)
			if element == 'protected-part'
				@curProtectedParts << Culter::CSE::ProtectedPart.new(@protectedParts.count - 1, attributes['begin'], attributes['end'], 'yes' == attributes['recursive'])
			elsif element == 'languagerule'
				@curProtectedParts = []
				@protectedParts[attributes['languagerulename']] = @curProtectedParts
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
		end
		
		include Culter::CSE::SegmenterFactory
			
	end
	
end

