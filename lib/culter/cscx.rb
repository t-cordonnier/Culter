# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/_xml'
require 'culter/csc'

##
# Implement a segmenter with Culter Segmentation Compatible as XML
# XML reader for CSC
# Format with only SRX-compatible markups: this is only a more readable format than SRX, 
# 
module Culter::CSC::XML

	class CscxCallbacks 	# :nodoc: all
		include REXML::StreamListener
		
		attr_reader :langRules, :mapRules, :defaultMapRule, :cascade, :formatHandle, :ruleTemplates
		
		def initialize()
			@langRules = {}
			@ruleTemplates = {}
			@defaultMapRule = []
			@curMapRule = @defaultMapRule
			@mapRules = {}
			@where = ''
			@cascade = false			# default
			@formatHandle = { 'start' => false, 'end' => true, 'isolated' => true }
		end
		
		# Set current rule to new item, and add it where necessary
		def newRule!(r)
			@curRule = r
			if @where == 'rewrite'
				@ruleTemplates[@curTemplate].rewriteRule = @curRule
			else
				@curLangRule << @curRule
			end
		end
		
		def newRuleName()
			if @file != nil then
				if @where == 'rewrite' then return "#{@file}:#{@curTemplate}" else return "#{@file}:#{@curName}/#{1 + @curLangRule.count}" end			
			else
				if @where == 'rewrite' then return @curTemplate else return "#{@curName}/#{1 + @curLangRule.count}" end
			end
		end		
		
		def tag_start(element, attributes)
			if element == 'seg-rules'
				if attributes['extends'] != nil then 
					if not File.exist? attributes['extends'] then
						attributes['extends'] = File.dirname(@file) + '/' + attributes['extends']
					end
					@extended = CscxCallbacks.new
					@extended.file = attributes['extends']
					File.open(attributes['extends'], 'r:UTF-8') { |source| REXML::Document.parse_stream(source, @extended) } 
					@ruleTemplates = @extended.ruleTemplates
				end				
			elsif element == 'rules-mapping'
				if attributes['cascade'] == 'true' then @cascade = true end
				@mappingExtMode =  attributes['extension-mode'] 
			elsif element == 'formathandle'
				@formatHandle[attributes['type']] = (attributes['include'] == 'yes')
			elsif element == 'languagemap'
				@curLangMap = Culter::SRX::LangMap.new(attributes['languagepattern'], attributes['languagerulename'])
				@curMapRule << @curLangMap
			elsif element == 'maprule'
				@curMapRule = []	# new empty array
				@mapRules[attributes['maprulename']] = @curMapRule
				@mappingExtMode =  attributes['extension-mode'] 
				@curName = attributes['maprulename']
			elsif element == 'languagerule'
				@curLangRule = []	# new empty array
				@langRules[attributes['languagerulename']] = @curLangRule
				@mappingExtMode =  attributes['extension-mode'] 
				@curName = attributes['languagerulename']
			elsif element == 'rule'     # Use srx
				newRule! Culter::SRX::Rule.new(attributes['break'] == 'yes', newRuleName())                
			elsif element == 'break-rule'     # Use srx
				newRule! Culter::SRX::Rule.new(true, newRuleName())
			elsif element == 'exception-rule'     # Use srx
				newRule! Culter::SRX::Rule.new(false, newRuleName())
			elsif element == 'rule-template'
				@curTemplate = attributes['name']
				@ruleTemplates[attributes['name']] = Culter::CSC::RuleTemplate.new(attributes['name'])
			elsif element == 'rule-template-param'
				@ruleTemplates[@curTemplate].params[attributes['name']] = attributes
			elsif element == 'apply-rule-template'
				@curTemplate = attributes['name']
			elsif element == 'loop'
				@loop = []
			elsif element == 'item-list-file'
                if attributes['format'] =~ /^te?xt(?:\:(.+))?$/	# one per line
					if $1 != nil then attributes['format'] = "r:#{$1}" else attributes['format'] = 'r' end
					if not File.exist? attributes['name']
						attributes['name'] = File.dirname(@file) + '/' + attributes['name']
					end
					if $CULTER_VERBOSE > 1 then puts "Reading #{attributes['name']}" end
					Culter::CSC::readTextFile(attributes['name'], attributes['format'], attributes['remove'], Regexp.new(attributes['comments'])) { |line| @loop << line.gsub(/\./, "\\.") }
				end
			end
			@where = element
		end
			
		def text(text) 
			if @where == 'beforebreak' then @curRule.before = text
			elsif @where == 'afterbreak' then @curRule.after = text
			elsif @where == 'item' then @loop << text
			end
		end
		
		def tag_end(element)			
			@where = ''
			if element == 'apply-rule-template'
				@curLangRule << Culter::CSC::ApplyRuleTemplate.new(@ruleTemplates[@curTemplate],@loop)
			elsif element == 'rules-mapping'
				if @mappingExtMode == 'before' then @extended.defaultMapRule.each { |r| @defaultMapRule << r } end
			elsif element == 'maprule'
				if @mappingExtMode == 'before' then @extended.mapRules[@curName].each { |r| @curMapRule << r } end			
			elsif element == 'languagerule'
				if @mappingExtMode == 'before' then 
					@extended.langRules[@curName].each { |r| @curLangRule << r } 
				elsif @mappingExtMode == 'after' then 
					dest = @extended.langRules[@curName].clone
					@curLangRule.each { |r| dest << r }
					@curLangRule = @langRules[@curName] = dest
				end	
			end
		end
		
		def file=(st) @file = st end		  
	end
	
	##
	# Loads a SRX document and can apply the rules
	class CscxDocument < Culter::CSC::CscDocument
		include Culter::XML::Load
	
		attr_reader :ruleTemplates
	
		def initialize(src)
			callback = CscxCallbacks.new
			load(src,'cscx',callback)
			
			@cascade = callback.cascade
			@mapRules = callback.mapRules
			@defaultMapRule = callback.defaultMapRule
			@langRules = callback.langRules
			@formatHandle = callback.formatHandle
			@ruleTemplates = callback.ruleTemplates
		end
		
		##
		# Produce an usable segmenter for the given language.
		def segmenter(lang, maprulename = '')
			if maprulename != '' then map = @maprules[maprulename] else map = @defaultMapRule end
			rules = []
			map.each do |langMap|
				if langMap.matches(lang) then
					@langRules[langMap.rulename].each do |r| 
						if r.is_a? Culter::SRX::Rule then rules << r
						elsif r.is_a? Culter::CSC::ApplyRuleTemplate then
							rules << r.to_rules
							if $CULTER_VERBOSE > 3 then
								puts "Built rule : #{r.to_rules.break} /#{r.to_rules.before}/ -> /#{r.to_rules.after}/"
							end
						end
					end
					if not(@cascade) then return Segmenter.new(rules,@formatHandle) end
				end
			end
			return Culter::SRX::Segmenter.new(rules,@formatHandle)
		end
			
	end
	
end

