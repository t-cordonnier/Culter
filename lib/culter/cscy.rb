# encoding: utf-8

require 'culter/csc'
require "yaml"

##
# YAML reader for CSC
# Format with only SRX-compatible markups: this is only a more readable format than SRX, 
# with capacity to create templates
# 
module Culter::CSC::YML

	
	##
	# Loads a SRX document and can apply the rules
	class CscyDocument < Culter::CSC::CscDocument
		def initialize(src)
			if src.is_a? String then
				if (src =~ /\.(ya?ml|#{extension})$/) then 	
					@file = src
					obj = YAML.load_file(File.open(src))
				else
					obj = YAML.load(src)
				end
			elsif src.is_a? IO
				obj = YAML.load(src)
			end
			
			@cascade = 'true'.eql? obj['rules-mapping']['cascade'].to_s
			@formatHandle = { 'start' => false, 'end' => true, 'isolated' => true }
			
			if obj['rules-mapping']['maps'].kind_of?(Array)
				@mapRules = { 'default' => to_langmap_array(obj['rules-mapping']['maps']) }
				@defaultMapRule = @mapRules['default']
			else
				@mapRules = {}
				obj['rules-mapping']['maps'].each_pair { |k,v| @mapRules[k] = to_langmap_array(v) }
				@defaultMapRule = obj['rules-mapping']['default']		
			end
						
			@ruleTemplates = {}
			obj['rule-templates'].each_pair { |k,v| @ruleTemplates[k] = to_rule_template(k, v) }			

			@langRules = {}
			obj['rules'].each_pair { |name,list| @langRules[name] = list.each_with_index.map { |v,idx| to_lang_rule("#{name}/#{idx}", v) } }
		end
		
		def extension() 'cscy' end
		
	private
		def to_langmap_array(yaml_list)
			res = Array.new
			yaml_list.each do |item| 
				item.each_pair { |k,v| res << Culter::SRX::LangMap.new(k, v) }
			end
			return res
		end
		
		def to_lang_rule(name, yaml_hash)
			if yaml_hash['type'] =~ /^break/
				rule = Culter::SRX::Rule.new(true, name)
				rule.before = yaml_hash['before']
				rule.after = yaml_hash['after']
			elsif yaml_hash['type'] =~ /^exception/
				rule = Culter::SRX::Rule.new(false, name)
				rule.before = yaml_hash['before']
				rule.after = yaml_hash['after']			
			elsif yaml_hash['type'] == 'apply-template'
				rule = Culter::CSC::ApplyRuleTemplate.new(@ruleTemplates[yaml_hash['template-name']],read_loop(yaml_hash['params'][0]['loop']))	
			end
			return rule
		end
		
		def read_loop(item)
			if item.is_a? String then return [item]			# one array
			elsif item.is_a? Array then 
				loop = []
				item.each { |item2| loop << read_loop(item2) }
				return loop
			elsif item.is_a? Hash then 
				if item['format'] =~ /^te?xt(?:\:(.+))?$/	# one per line
					if $1 != nil then item['format'] = "r:#{$1}" else item['format'] = 'r' end
					if not File.exist? item['file']
						if @file != nil then 
							item['file'] = File.dirname(@file) + '/' + item['file']
						end
					end
					if $CULTER_VERBOSE > 1 then puts "Reading #{item['file']}" end		
					loop = []
					Culter::CSC::readTextFile(item['file'], item['format'], item['remove'],item['comments']) { |line| loop << line }
					return loop
				end						
			end
		end
		
		def to_rule_template(name, yaml_hash)
			tpl = Culter::CSC::RuleTemplate.new(name)
			tpl.params=yaml_hash['params']
			tpl.rewriteRule = to_lang_rule(name, yaml_hash['rewrite'])
			return tpl
		end
	end

end

