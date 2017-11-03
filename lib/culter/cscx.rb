# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/srx'

##
# Implement a segmenter with Culter Segmentation Compatible as XML
# XML-based format with only SRX-compatible markups: this is only a more readable format than SRX, 
# with capacity to create templates
# 
module Culter::CSCX

	class RuleTemplate
		attr_accessor :params, :rewriteRule
		
		def initialize()
			@params = {}
		end
	end

	class ApplyRuleTemplate
		def initialize(templateRef, loop)
			@ruleRef = templateRef.rewriteRule
			@items = loop
		end
		
		def to_rules
			rule = Culter::SRX::Rule.new(@ruleRef.break)
			rule.before = @ruleRef.before.gsub(/\%\{(\w+)\}/, @items.join("|"))
			rule.after = @ruleRef.after.gsub(/\%\{(\w+)\}/, @items.join("|"))            
			return rule
		end
	end
    
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
		
		def tag_start(element, attributes)
			if element == 'rules-mapping'
				if attributes['cascade'] == 'true' then @cascade = true end
			elsif element == 'formathandle'
				@formatHandle[attributes['type']] = (attributes['include'] == 'yes')
			elsif element == 'languagemap'
				@curLangMap = Culter::SRX::LangMap.new(attributes['languagepattern'], attributes['languagerulename'])
				@curMapRule << @curLangMap
			elsif element == 'maprule'
				@curMapRule = []	# new empty array
				@mapRules[attributes['maprulename']] = @curMapRule
			elsif element == 'languagerule'
				@curLangRule = []	# new empty array
				@langRules[attributes['languagerulename']] = @curLangRule
			elsif element == 'rule'     # Use srx
				newRule! Culter::SRX::Rule.new(attributes['break'] == 'yes')                
			elsif element == 'break-rule'     # Use srx
				newRule! Culter::SRX::Rule.new(true)
			elsif element == 'exception-rule'     # Use srx
				newRule! Culter::SRX::Rule.new(false)
			elsif element == 'rule-template'
				@curTemplate = attributes['name']
				@ruleTemplates[attributes['name']] = RuleTemplate.new
			elsif element == 'rule-template-param'
				@ruleTemplates[@curTemplate].params[attributes['name']] = attributes
			elsif element == 'apply-rule-template'
				@curTemplate = attributes['name']
			elsif element == 'loop'
				@loop = []
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
				@curLangRule << ApplyRuleTemplate.new(@ruleTemplates[@curTemplate],@loop)
			end
		end
		  
	end
	
	##
	# Loads a SRX document and can apply the rules
	class CscxDocument
	
		def initialize(src)
			callback = CscxCallbacks.new
			if src.is_a? String then
				if (src =~ /\.(xml|cscx)$/) then 
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
						elsif r.is_a? ApplyRuleTemplate then rules << r.to_rules
						end
					end
					if not(@cascade) then return Segmenter.new(rules,@formatHandle) end
				end
			end
			return Culter::SRX::Segmenter.new(rules,@formatHandle)
		end
			
	end
	
end

