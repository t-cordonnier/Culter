# encoding: utf-8


module Culter end			# only to avoid errors

module Culter::XML end

module Culter::XML::Load

	def load(src, extension, callback)
		if src.is_a? String then
			if (src =~ /\.(xml|#{extension})$/) then 
				if callback.respond_to?('file=') then callback.file = src end
				File.open(src, 'r:UTF-8') { |source| REXML::Document.parse_stream(source, callback) } 
			elsif src =~ /<\w/
				REXML::Document.parse_stream(src, callback)
			end
		elsif src.is_a? IO
			REXML::Document.parse_stream(src, callback)
		end
	end

end
	
module Culter::XML::Convert

	##
	# Display the result in SRX format
	# Param dest (IO): if present, write to the IO. Else, return a string
	# Param version: can be used to generate SRX 1.0
	# Param langs: if provided, array of languages to generate an non-cascade SRX file
	# Param mapruleName: to generate SRX 2.0 from other format having several rule names, select one
	def to_srx(dest = nil, version = '2.0', langs = nil, mapruleName = nil)
		if dest == nil
			dest = StringIO.new
			to_srx(dest, version, langs, mapRuleName)
			return dest
		else
			dest.puts "<srx version='#{version}' xmlns='http://www.lisa.org/srx#{version.gsub(/\./,'')}'>"
			if version =~ /^1/ then 
				dest.puts "\t<header segmentsubflows='true' />"
			else
				if langs == nil then cascadeSt = @cascade end
				if cascadeSt then cascadeSt = 'yes' else cascadeSt = 'no' end				
				dest.puts "\t<header segmentsubflows='yes' cascade='#{cascadeSt}'>"
				@formatHandle.each do |k,v| 
					dest.write "\t\t<formathandle type='#{k}' "
					if v then dest.puts "include='yes' />" else dest.puts "include='no' />" end 
				end
				dest.puts "\t</header>"
			end
			dest.puts "\t<body>"
			dest.puts "\t\t<languagerules>"
			if langs == nil then
				@langRules.each do |k,v| 
					dest.puts "\t\t\t<languagerule languagerulename='#{k}'>"
					v.each { |r| r.to_srx(dest) }
					dest.puts "\t\t\t</languagerule>"
				end
			else
				langs.each do |lg|
					dest.puts "\t\t\t<languagerule languagerulename='#{lg}'>"
					self.segmenter(lg,mapruleName == nil ? '' : mapruleName).rules.each { |r| r.to_srx(dest) }
					dest.puts "\t\t\t</languagerule>"					
				end				
			end
			dest.puts "\t\t</languagerules>"
			dest.puts "\t\t<maprules>"
			if langs != nil then
				if mapruleName == nil then mapruleName = 'default' end
				if version =~ /^1/ then dest.puts "<maprule maprulename='#{mapruleName}'>" end
				langs.each { |lg| dest.puts "\t\t<languagemap languagepattern='#{lg}' languagerulename='#{lg}' />" }
				if version =~ /^1/ then dest.puts "</maprule>" end
			else
				if version =~ /^1/ then
					if mapruleName != nil then 
						maps = { mapruleName => mapRules[mapruleName] }
					elsif @mapRules.empty? then
						maps = { 'default' => @defaultMapRule }
					end
					maps.each do |k,v|
						dest.puts "\t\t\t<maprule maprulename='#{k}'>"
						v.each { |i| dest.puts "\t\t\t#{i.to_srx}" }
						dest.puts "\t\t\t</maprule>"
					end
				else
					if mapruleName != nil then curMapRule = @mapRules[mapruleName] else curMapRule = @defaultMapRule end
					curMapRule.each { |i| dest.puts "\t\t\t#{i.to_srx}" }
				end
			end
			dest.puts "\t\t</maprules>"				
			dest.puts "\t</body>"
			dest.puts "</srx>"
		end
	end
	
		
	##
	# Display the result in CSCX format
	# Param dest (IO): if present, write to the IO. Else, return a string
	# Param langs: if provided, array of languages to generate an non-cascade SRX file
	# Param mapruleName: restrict to one map rule
	def to_cscx(dest = nil, langs = nil, mapruleName = nil)
		if dest == nil
			dest = StringIO.new
			to_cscx(dest, version, cascade, mapRuleName)
			return dest
		else
			dest.puts "<seg-rules xmlns='http://culter.silvestris-lab.org/compatible'>"
			dest.puts "\t<format-handles>"
			@formatHandle.each do |k,v| 
				dest.write "\t\t<formathandle type='#{k}' "
				if v then dest.puts "include='yes' />" else dest.puts "include='no' />" end 
			end
			dest.puts "\t</format-handles>"	
			if langs == nil then cascadeSt = @cascade else cascade = false end
			dest.puts "\t<rules-mapping cascade='#{cascadeSt}'>"
			if langs != nil then
				langs.each { |lg| dest.puts "\t\t<languagemap languagepattern='#{lg}' languagerulename='#{lg}' />" }
			else
				if mapruleName != nil then 
					@mapRules[mapruleName].each { |i| dest.puts "\t\t\t#{i.to_srx}" }
				elsif @mapRules.keys.count > 1
					@mapRules.each do |mapName,mapVal|
						dest.puts "\t\t<rules-mapping-option name='#{mapName}'>"
						mapVal.each { |i| dest.puts "\t\t\t#{i.to_srx}" }
						dest.puts "\t\t</rules-mapping-option>"
					end
				else
					@defaultMapRule.each { |i| dest.puts "\t\t\t#{i.to_srx}" }
				end
			end
			dest.puts "\t</rules-mapping>"
			if self.respond_to? 'ruleTemplates' then
				dest.puts "\t<rule-templates>"
				self.ruleTemplates.each do |k,v| 
					dest.puts "\t\t<rule-template name='#{k}'>"
					v.params.each { |k1,v1| dest.puts "\t<rule-template-param name='#{k1}' join='|' />" }
					dest.puts "\t\t\t<rewrite>"
					v.rewriteRule.to_srx(dest)
					dest.puts "\t\t\t</rewrite>"					
					dest.puts "\t\t</rule-template>"
				end
				dest.puts "\t</rule-templates>"				
			end
			dest.puts "\t<languagerules>"
			if langs == nil then
				@langRules.each do |k,v| 
					dest.puts "\t\t<languagerule languagerulename='#{k}'>"
					v.each { |r| r.respond_to?('to_cscx') ? r.to_cscx(dest) : r.to_srx(dest) }
					dest.puts "\t\t</languagerule>"
				end
			else
				langs.each do |lg|
					dest.puts "\t\t<languagerule languagerulename='#{lg}'>"
					self.segmenter(lg,mapruleName == nil ? '' : mapruleName).rules.each { |r| r.respond_to?('to_cscx') ? r.to_cscx(dest) : r.to_srx(dest) }
					dest.puts "\t\t</languagerule>"					
				end				
			end
			dest.puts "\t</languagerules>"
			dest.puts "</seg-rules>"
		end
	end
	
end

