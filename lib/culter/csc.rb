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
		attr_accessor :rewriteRule, :name
		
		def initialize(name)
			@name = name
		end
		
		def to_yaml_struct()  
			return { 'rewrite' => @rewriteRule.to_yaml_struct() }			
		end		
	end

	class ApplyRuleTemplate
		def initialize(templateRef, params)
			@ruleRef = templateRef
			@params = params
		end
		
		def build_param_expression(param_name)
			if @params[param_name].is_a? Array then @params[param_name].join("|")	# convert to long string, with 'OR'
			elsif @params[param_name].is_a? String then @params[param_name]			# string: as is
			end
		end
		
		def name() @ruleRef.name end
		
		def to_rules(mode = 'machine')
			if mode == 'machine'
				# Builds one long rule : this is faster
				rule = Culter::SRX::Rule.new(@ruleRef.rewriteRule.break, "Template:#{@ruleRef.name}")
				rule.before = @ruleRef.rewriteRule.before.gsub(/\%\{(\w+)\}/) { build_param_expression($1) }
				rule.after = @ruleRef.rewriteRule.after.gsub(/\%\{(\w+)\}/) { build_param_expression($1) }
				return rule		
			elsif mode == 'human'
				# Builds long list of rules: slower but more human-readable
				befores = [ @ruleRef.rewriteRule.before.dup ]; afters = [ @ruleRef.rewriteRule.after.dup ]
				@params.each do |key, val|
					if val.is_a? String then
						befores.each { |item| item.gsub!(/\%\{#{key}\}/, val) }
						afters.each { |item| item.gsub!(/\%\{#{key}\}/, val) }
					elsif val.is_a? Array then
						if @ruleRef.rewriteRule.before =~ /\%\{#{key}\}/
							tmp = []
							befores.each do |item|
								val.each { |val0| tmp << item.gsub(/\%\{#{key}\}/, val0) }
							end
							befores = tmp
						end
						if @ruleRef.rewriteRule.after =~ /\%\{#{key}\}/
							tmp = []
							afters.each do |item|
								val.each { |val0| tmp << item.gsub(/\%\{#{key}\}/, val0) }
							end
							afters = tmp
						end
					end
				end
				list = []
				befores.each do |bef0|
					afters.each do |aft0|
						rule = Culter::SRX::Rule.new(@ruleRef.rewriteRule.break, "Template:#{@ruleRef.name}/#{bef0}/#{aft0}")
						rule.before = bef0
						rule.after = aft0
						list << rule
					end
				end
				return list
			end
		end
		
		def to_srx(dest, mode = 'machine')
			if mode == 'machine'
				to_rules('machine').to_srx(dest)
			elsif mode == 'human'
				to_rules('human').each { |r| r.to_srx(dest) }
			end
		end
		
		def to_cscx(dest)
			dest.puts "\t\t\t<apply-rule-template name='#{@ruleRef.name}'>"
			@params.each do |key, val|
				if val.is_a? String then dest.puts "\t\t\t\t<param name='#{key}' value='#{val}' />\n"
				elsif val.is_a? Array then 
					dest.puts "\t\t\t\t<param name='#{key}' mode='loop'>\n"
					val.each { |item| dest.puts "\t\t\t\t\t<item>#{item}</item>\n" }
					dest.puts "\t\t\t\t</param>"
				end
			end
			dest.puts "\t\t\t</apply-rule-template>"
		end		
		
		def to_yaml_struct()  
			res = { 'type' => 'apply-rule-template', 'template-name' => @ruleRef.name }
			res['params'] = []
			@params.each do |key,val| 
				if val.is_a? String then res['params'] << { 'name' => key, 'value' => val } 
				elsif val.is_a? Array then res['params'] << { 'name' => key, 'loop' => val } 
				end
			end 			
			return res
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
		attr_reader :ruleTemplates, :langRules
	
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
		
		def to_yaml_struct(mapruleName = nil)  
			res = { 'rules' => {}, 'rules-mapping' => { 'maps' => [] } }
			res['rules-mapping']['cascade'] = @cascade
			if mapruleName != nil then curMapRule = @mapRules[mapruleName] else curMapRule = @defaultMapRule end
			curMapRule.each do |i| res['rules-mapping']['maps'] << { i.pattern.to_s => i.rulename } end
			@langRules.each do |k,v| res['rules'][k] = v.collect { |rule| rule.to_yaml_struct() } end
			res['rule-templates'] = {}
			ruleTemplates.each do |name, item| res['rule-templates'][name] = item.to_yaml_struct() end
			return res
		end		
	end
	
end

