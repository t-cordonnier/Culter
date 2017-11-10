# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/_xml'
require 'culter/srx'

##
# Implement a segmenter with Culter Segmentation Compatible as XML
# XML-based format with only SRX-compatible markups: this is only a more readable format than SRX, 
# with capacity to create templates
# 
module Culter::CSCX

	class RuleTemplate
		attr_accessor :params, :rewriteRule, :name
		
		def initialize(name)
			@name = name
			@params = {}
		end
	end

	class ApplyRuleTemplate
		def initialize(templateRef, loop)
			@ruleRef = templateRef
			@items = loop
		end
		
		def to_rules
			rule = Culter::SRX::Rule.new(@ruleRef.rewriteRule.break)
			rule.before = @ruleRef.rewriteRule.before.gsub(/\%\{(\w+)\}/, @items.join("|"))
			rule.after = @ruleRef.rewriteRule.after.gsub(/\%\{(\w+)\}/, @items.join("|"))            
			return rule		
		end
		
		def to_srx(dest)
			to_rules().to_srx(dest)
		end
		
		def to_cscx(dest)
			dest.puts "\t\t\t<apply-rule-template name='#{@ruleRef.name}'>"
			dest.puts "\t\t\t\t<loop param='#{ruleRef.params.keys[0]}'>"
			@items.each { |item| dest.puts "\t\t\t\t<item>#{@item}</item>" }
			dest.puts "\t\t\t\t</loop>"
			dest.puts "\t\t\t</apply-rule-template>"
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
				@ruleTemplates[attributes['name']] = RuleTemplate.new(attributes['name'])
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
					File.open(attributes['name'], attributes['format']) do |f|
						i = 0
						while line = f.gets
							line.gsub! /\r?\n$/, ''
							if attributes['remove'] then line.gsub!(Regexp.new(attributes['remove']),'') end
							if attributes['comments'] and line =~ Regexp.new(attributes['comments']) then next end
							if line.length > 0 then
								@loop << line
								i = i + 1
							end
						end	
						if $CULTER_VERBOSE > 2 then puts "#{attributes['name']}: #{i} items added" end
					end
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
				@curLangRule << ApplyRuleTemplate.new(@ruleTemplates[@curTemplate],@loop)
			end
		end
		
		def file=(st) @file = st end		  
	end
	
	##
	# Loads a SRX document and can apply the rules
	class CscxDocument
		include Culter::XML
	
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
						elsif r.is_a? ApplyRuleTemplate then
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

