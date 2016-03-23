# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

module Culter end

##
# Implement a segmenter with a SRX (1.0 or 2.0) document
module Culter::SRX

	class Rule		# :nodoc: all
		attr_reader :break
		attr_reader :before, :after
		
		def initialize(isBreak)
			@break = isBreak
		end
        
		# setters for rules: even if the text uses parenthesis, avoid grouping
		def before= (st) @before = st.gsub(/(?<!\\)\((?!\?[a-z]*:)/,'(?:') end
		def after= (st) @after = st.gsub(/(?<!\\)\((?!\?[a-z]*:)/,'(?:') end
        
		def prepare!(segmenter,formatHandle)
			before = []; after = []
			if formatHandle['start'] then before << segmenter.tagStart else after << segmenter.tagStart end 
			if formatHandle['end'] then before << segmenter.tagEnd else after << segmenter.tagEnd end 
			if formatHandle['isolated'] then before << segmenter.tagIsolated else after << segmenter.tagIsolated end 
			if before.count > 0 then before = "#{self.before}(?:" + before.join('|') + ")*" else before = self.before end
			if after.count > 0 then after = "(?:" + after.join('|') + ")*#{self.after}" else after = self.after end				
			@regex = %r{(#{before})(#{after})}
		end
		
		def apply!(st)
			if self.break then subst = "\\1\uE001\\2" else subst = "\\1\uE000\\2" end
			st.gsub!(@regex, subst)
		end        
	end

	class LangMap 	# :nodoc: all
		attr_reader :rulename
		
		def initialize(pattern, rulename)
			if pattern.is_a? String then pattern = %r(#{pattern}) end
			@pattern = pattern
			@rulename = rulename
		end
		
		def matches(lang) 
			return (lang =~ @pattern) != nil
		end
	end
	
	class SrxCallbacks 	# :nodoc: all
		include REXML::StreamListener
		
		attr_reader :langRules, :mapRules, :defaultMapRule, :cascade, :formatHandle
		
		def initialize()
			@langRules = {}
			@defaultMapRule = []
			@curMapRule = @defaultMapRule
			@mapRules = {}
			@where = ''
			@cascade = false			# default
			@formatHandle = { 'start' => false, 'end' => true, 'isolated' => true }
		end
		
		def tag_start(element, attributes)
			if element == 'header'
				if attributes['cascade'] == 'yes' then @cascade = true end
			elsif element == 'formathandle'
				@formatHandle[attributes['type']] = (attributes['include'] == 'yes')
			elsif element == 'languagemap'
				@curLangMap = LangMap.new(attributes['languagepattern'], attributes['languagerulename'])
				@curMapRule << @curLangMap
			elsif element == 'maprule'
				@curMapRule = []	# new empty array
				@mapRules[attributes['maprulename']] = @curMapRule
			elsif element == 'languagerule'
				@curLangRule = []	# new empty array
				@langRules[attributes['languagerulename']] = @curLangRule
			elsif element == 'rule'
				@curRule = Rule.new(attributes['break'] == 'yes')
				@curLangRule << @curRule
			end
			@where = element
		end
			
		def text(text) 
			if @where == 'beforebreak' then @curRule.before = text
			elsif @where == 'afterbreak' then @curRule.after = text
			end
		end
		
		def tag_end(element)			
			@where = ''
		end
		  
	end
	
	##
	# Loads a SRX document and can apply the rules
	class SrxDocument
	
		def initialize(src)
			callback = SrxCallbacks.new
			if src.is_a? String then
				if (src =~ /\.(xml|srx)$/) then 
					File.open(src, 'r:UTF-8') { |source| REXML::Document.parse_stream(source, callback) } 
				elsif src =~ /<\w/
					REXML::Document.parse_stream(src, callback)
					puts "Callback : #{callback.cascade}"
				end
			elsif src.is_a? IO
				REXML::Document.parse_stream(src, callback)
			end
			
			@cascade = callback.cascade
			@mapRules = callback.mapRules
			@defaultMapRule = callback.defaultMapRule
			@langRules = callback.langRules
			@formatHandle = callback.formatHandle
		rescue Exception => e
			puts "Error during parsing: #{e}"
		end
		
		##
		# Produce an usable segmenter for the given language.
		# Parameter "maprulename" is used only for SRX 1.0
		def segmenter(lang, maprulename = '')
			if maprulename != '' then map = @maprules[maprulename] else map = @defaultMapRule end
			rules = []
			map.each do |langMap|
				if langMap.matches(lang) then
					@langRules[langMap.rulename].each { |r| rules << r }
					if not(@cascade) then return Segmenter.new(rules,@formatHandle) end
				end
			end
			puts "#{rules.count} rules found."
			return Segmenter.new(rules,@formatHandle)
		end
		
	end
	
	class Segmenter
	
		attr_reader :tagStart, :tagEnd, :tagIsolated
	
		def initialize(rules,formatHandle)
			@rules = rules
			@formatHandle = formatHandle
			@tagStart = '<\w[\w\-]*?(?:\s+[\w\-]+\s*=\s*[\"\'][^\"\']+[\"\'])*>'
			@tagEnd = '</\w[\w\-]*?\s*>'
			@tagIsolated = '<\w[\w\-]*?(?:\s+[\w\-]+\s*=\s*[\"\'][^\"\']+[\"\'])*\s*/\s*>'
			@rules.each { |rule| rule.prepare!(self,formatHandle) }
		end
		
		def change_tags!(tagStart,tagEnd,tagIsolated)
			@tagStart = tagStart
			@tagEnd = tagEnd
			@tagIsolated = tagIsolated
			@rules.each { |rule| rule.prepare!(self,@formatHandle) }		
		end
	
		def cut(st)
			st = st.clone
			st.force_encoding('UTF-8')	# else, \uE000n may not work
			@rules.each { |rule| rule.apply!(st) }
			st.gsub!("\uE000", '')
			if block_given?
				st.scan(/(.+?)(\uE001|$)/) { yield $1 }
			else
				return st.split(/\uE001/)
			end
		end
	
		def rulesCount() @rules.count end
	end
	
end

