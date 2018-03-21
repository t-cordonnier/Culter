# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/_xml'

##
# Implement a segmenter with a SRX (1.0 or 2.0) document
module Culter::SRX

	class Rule		# :nodoc: all
		attr_reader :break
		attr_reader :before, :after
		attr_reader :ruleName
		
		def initialize(isBreak, name = nil)
			@break = isBreak
			if name == nil then @ruleName = "#{@before}!#{@after}" else @ruleName = name end
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
		
		def apply_debug!(st)			
			st.gsub!(@regex, "\\1<#{@ruleName}:#{@break}>\\2")
		end  		
		
		def to_srx(dest)
			dest.write "\t\t\t\t<rule "
			if @break then dest.puts 'break="yes">' else dest.puts 'break="no">' end
			if before != nil then dest.puts "\t\t\t\t\t<beforebreak>#{before.gsub(/\(\?\:/,'(')}</beforebreak>" end
			if after != nil then dest.puts "\t\t\t\t\t<afterbreak>#{after.gsub(/\(\?\:/,'(')}</afterbreak>" end
			dest.puts "\t\t\t\t</rule>"			
		end
		
		def to_yaml_struct()  
			res = { 'before' => @before, 'after' => @after }
			if @break then res['type'] = 'break-rule' else res['type'] = 'exception-rule' end
			return res
		end
	end

	class LangMap 	# :nodoc: all
		attr_reader :rulename, :pattern
		
		def initialize(pattern, rulename)
			if pattern.is_a? String then pattern = %r(#{pattern}) end
			@pattern = pattern
			@rulename = rulename
		end
		
		def matches(lang) 
			return (lang =~ @pattern) != nil
		end
		
		def to_srx() "<languagemap languagepattern='#{@pattern}' languagerulename='#{rulename}' />" end
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
				@curLangRuleName = attributes['languagerulename']
				@langRules[attributes['languagerulename']] = @curLangRule
			elsif element == 'rule'
				@curRule = Rule.new(attributes['break'] == 'yes')
				@curRule = Rule.new(attributes['break'] == 'yes', "#{@curLangRuleName}/#{1 + @curLangRule.count}")
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
		include Culter::XML::Load
	
		def initialize(src)
			callback = SrxCallbacks.new
			load(src,'srx',callback)
			
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
			return Segmenter.new(rules,@formatHandle)
		end
		
		def to_yaml_struct(mapruleName = nil)  
			res = { 'rules' => {}, 'rules-mapping' => { 'maps' => [] } }
			res['rules-mapping']['cascade'] = @cascade
			if mapruleName != nil then curMapRule = @mapRules[mapruleName] else curMapRule = @defaultMapRule end
			curMapRule.each do |i| res['rules-mapping']['maps'] << { i.pattern.to_s => i.rulename } end
			@langRules.each do |k,v| res['rules'][k] = v.collect { |rule| rule.to_yaml_struct() } end
			return res
		end
	end
	
	class Segmenter
	
		attr_reader :tagStart, :tagEnd, :tagIsolated, :rules
	
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
	
		def cut_debug(st)
            st = st.clone
			@rules.each { |rule| rule.apply_debug!(st) }
			return st
		end		
	
		def rulesCount() @rules.count end
	end
	
end

