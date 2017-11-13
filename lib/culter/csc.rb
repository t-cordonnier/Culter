# encoding: utf-8

require 'rexml/document'
require "rexml/streamlistener"

require 'culter/srx'

##
# Implement a segmenter with Culter Segmentation Compatible as XML
# XML-based format with only SRX-compatible markups: this is only a more readable format than SRX, 
# with capacity to create templates
# 
module Culter::CSC

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
	
	def self.readTextFile(filename, format, remove, comments)
		File.open(filename, format) do |f|
			i = 0
			while line = f.gets
				line.gsub! /\r?\n$/, ''
				if remove then line.gsub!(Regexp.new(remove),'') end
				next if comments and line =~ comments
				if line.length > 0 then
					yield line
					i = i + 1
				end
			end	
			if $CULTER_VERBOSE > 2 then puts "#{filename}: #{i} items added" end
		end
	end
	
	##
	# Loads a SRX document and can apply the rules
	class CscDocument
		attr_reader :ruleTemplates
	
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
		
		include Culter::XML::Convert
	end
	
end

