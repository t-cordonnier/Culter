# encoding: utf-8

require 'culter/srx'

##
# Implement a segmenter with Culter Segmentation Extended as XML
# Format with specific extensions which are NOT possible via SRX
# 
module Culter::CSE

	class ProtectedPart
		def initialize(pos,bg,en,recursive)
			@begin = bg
			@end = en
			@pos = pos
			@recursive = recursive
		end
		
		def apply!(st,mem)            
			i = 0
			if @recursive then
				# Warning: may not work in alternate Ruby versions!
				st.gsub! (/#{@begin}(.+|\g<0>)#{@end}/) { |txt| mem << txt; i = i + 1; "\uE002#{@pos};#{i - 1}\uE002" }
			else
				st.gsub! (/#{@begin}(.+?)#{@end}/) { |txt| mem << txt; i = i + 1; "\uE002#{@pos};#{i - 1}\uE002" }
			end
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
    

	module SegmenterFactory	
		
		##
		# Produce an usable segmenter for the given language.
		def segmenter(lang, maprulename = '')
			if maprulename != '' then map = @maprules[maprulename] else map = @defaultMapRule end
			rules = []; protectedParts = []
			map.each do |langMap|
				if langMap.matches(lang) then
					@langRules[langMap.rulename].each do |r| 
						if r.is_a? Culter::SRX::Rule then rules << r
						elsif r.is_a? Culter::CSC::ApplyRuleTemplate then rules << r.to_rules
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

