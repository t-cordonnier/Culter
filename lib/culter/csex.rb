# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/srx'
require 'culter/cscx'

##
# Implement a segmenter with Culter Segmentation Extended as XML
# XML-based format with specific extensions which are NOT possible via SRX
# 
module Culter::CSEX

	class ProtectedPart
		def initialize(pos,bg,en)
			@begin = bg
			@end = en
			@pos = pos
		end
		
		def apply!(st,mem)            
			i = 0
			st.gsub! (/#{@begin}(.+?)#{@end}/) { |txt| mem << txt; i = i + 1; "\uE002#{@pos};#{i - 1}\uE002" }
		end
        
		def restore!(st,mem)
			st.gsub! (/\uE002#{@pos};(\d+)\uE002/) { mem[$1.to_i] }
		end
	end
    
	class SuperSegmenter < Culter::SRX::Segmenter
        
		def initialize(rules,formatHandle, protectedParts)
			super(rules, formatHandle)
			@protectedParts = protectedParts
		end
        
		def cut(st)
			st = st.clone
			mem = []; @protectedParts.each { |p| p.apply!(st,mem) }
			if block_given?
				super(st) do |item| 
					@protectedParts.each { |p| p.restore!(item,mem) }
					yield item
				end
			else
				res = []
				super(st) do |item|
					@protectedParts.each { |p| p.restore!(item,mem) }
					res << item
				end
				return res
			end
		end	        
        
		def protectedPartsCount() @protectedParts.count end

	end
    
	
	class CsexCallbacks < Culter::CSCX::CscxCallbacks	# :nodoc: all
		attr_reader :protectedParts
		
		def initialize()
			super
            @protectedParts = {}
		end
		
		def tag_start(element, attributes)
			if element == 'protected-part'
				@curProtectedParts << ProtectedPart.new(@protectedParts.count - 1, attributes['begin'], attributes['end'])
			elsif element == 'languagerule'
				@curProtectedParts = []
				@protectedParts[attributes['languagerulename']] = @curProtectedParts
			end
			super(element, attributes)
		end		  
	end
	
	##
	# Loads a SRX document and can apply the rules
	class CsexDocument < Culter::CSCX::CscxDocument
	
		def initialize(src)
			callback = CsexCallbacks.new
			if src.is_a? String then
				if (src =~ /\.(xml|csex)$/) then 
					File.open(src, 'r:UTF-8') { |source| REXML::Document.parse_stream(source, callback) } 
				elsif src =~ /<\w/
					REXML::Document.parse_stream(src, callback)
				end
			elsif src.is_a? IO
				REXML::Document.parse_stream(src, callback)
			end
			
			@cascade = callback.cascade
			@mapRules = callback.mapRules
			@defaultMapRule = callback.defaultMapRule
			@langRules = callback.langRules
			@formatHandle = callback.formatHandle
			@protectedParts = callback.protectedParts
		end
		
		##
		# Produce an usable segmenter for the given language.
		def segmenter(lang, maprulename = '')
			if maprulename != '' then map = @maprules[maprulename] else map = @defaultMapRule end
			rules = []; protectedParts = []
			map.each do |langMap|
				if langMap.matches(lang) then
					@langRules[langMap.rulename].each do |r| 
						if r.is_a? Culter::SRX::Rule then rules << r
						elsif r.is_a? Culter::CSCX::ApplyRuleTemplate then rules << r.to_rules
						end
                    end
					@protectedParts[langMap.rulename].each { |r| protectedParts << r }
					if not(@cascade) then return SuperSegmenter.new(rules,@formatHandle,protectedParts) end                    
				end
			end
			return SuperSegmenter.new(rules,@formatHandle,protectedParts)
		end
			
	end
	
end

