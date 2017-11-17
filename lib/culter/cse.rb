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
	
	class SuperRule < Culter::SRX::Rule		# :nodoc: all
		attr_accessor :beforeKeep, :afterKeep
		
		def initialize(isBreak)
			@break = isBreak
			@beforeKeep = nil; @afterKeep = nil
		end
        
		# setters for rules: special case if keep is something
		def before=(st) 
			if beforeKeep == nil then super(st) else @before = st end			
		end
		def after=(st) 
			if afterKeep == nil then super(st) else @after = st end
		end
        
		def protect_item(st,num)
			i = 0; 1 while st.gsub! (/\(([^<].+|\g<0>)\)/) { |item| i = i + 1; "(<#{i}>#{$1})" }
			st.gsub! /\(<#{num}>/, '('	# only for this instance
			st.gsub! /\(<\d+>/, '('	# for all others
			return "(?:#{st})"
		end
		
		def prepare!(segmenter,formatHandle)
			beforeTags = []; afterTags = []
			if formatHandle['start'] then beforeTags << segmenter.tagStart else afterTags << segmenter.tagStart end 
			if formatHandle['end'] then beforeTags << segmenter.tagEnd else afterTags << segmenter.tagEnd end 
			if formatHandle['isolated'] then beforeTags << segmenter.tagIsolated else afterTags << segmenter.tagIsolated end 
			if beforeKeep == nil then 
				beforeSt = "(#{self.before})"
			elsif beforeKeep =~ /^\$(\d+)/ 
				beforeSt = self.before; beforeSt = protect_item(beforeSt, $1)
			end
			if afterKeep == nil then 
				afterSt = "(#{self.after})"
			elsif afterKeep =~ /^\$(\d+)/ 
				afterSt = self.after; afterSt = protect_item(afterSt, $1)
			end
			if beforeTags.count > 0 then beforeSt = "#{beforeSt}(?:" + beforeTags.join('|') + ")*" end
			if afterTags.count > 0 then afterSt = "(?:" + afterTags.join('|') + ")*#{afterSt}"  end
			@regex = %r{#{beforeSt}#{afterSt}}
		end
	end	
    
	class SuperSegmenter < Culter::SRX::Segmenter
        
		def initialize(rules,formatHandle, protectedParts,join)
			super(rules, formatHandle)
			@protectedParts = protectedParts
			@join = join
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
		def joinString() @join end

		def join(array)
			if @join == nil then return array.join('') else return array.join(@join) end
		end
		
	end
    

	module SegmenterFactory	
		
		##
		# Produce an usable segmenter for the given language.
		def segmenter(lang, maprulename = '')
			if maprulename != '' then map = @maprules[maprulename] else map = @defaultMapRule end
			rules = []; protectedParts = []; curJoin = nil
			map.each do |langMap|
				if langMap.matches(lang) then
					@langRules[langMap.rulename].each do |r| 
						if r.is_a? Culter::SRX::Rule then rules << r
						elsif r.is_a? Culter::CSC::ApplyRuleTemplate then rules << r.to_rules
						end
                    end
					@protectedParts[langMap.rulename].each { |r| protectedParts << r }
					if curJoin == nil then curJoin = @joins[langMap.rulename] end
					if not(@cascade) then return SuperSegmenter.new(rules,@formatHandle,protectedParts,curJoin) end                    
				end
			end
			return SuperSegmenter.new(rules,@formatHandle,protectedParts,curJoin)
		end
			
	end
	
end

