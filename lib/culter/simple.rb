
module Culter

	##
	# The simplest possible segmentation system : cuts for any instance of the symbols 
	# Default symbols are . ! and ?. You can define symbols in the constructor 
	class Simple

		##
		# Build simple segmenter 
		# Parameters:
		# [symbols]	Which symbols to be used. Defaults to '.', '!' and '?'
		# [spaces]	Which symbols are ignored just after the separator. Defaults to spaces
		# [needs_upper] 	Indicates that we cut only if followed by an upercase letter.
		def initialize(symbols = [ '.', '!', '?'], spaces = '\s*', needs_upper = true)
			if needs_upper then @re = %r(([#{symbols.join}])#{spaces}(?=\p{Upper}|$)) else @re = %r(([#{symbols.join}])#{spaces}) end 
		end
	
		##
		# Applies &sub for each segment of st
		def cut(st)
			tab = st.split(@re)
			res = []
			while phrase = tab.shift
				phrase2 = tab.shift
				if phrase2 != nil then phrase = phrase + phrase2 end # concat to next one containing the separator
				if block_given?
					yield phrase
				else
					res << phrase 
				end
			end
			return res unless block_given?
		end
		
		def name() 'Simple segmenter' end
	end
	
	##
	# This class makes possible to use several segmenters.
	class Combine
	
		##
		# Build a combination of segmenters
		# Parameter list must contain an array of segmenters.
		def initialize(list)
			@list = list
		end
		
		##
		# Applies &sub for each segment of st
		def cut(st)
			tab1 = [ st ]
			@list.each do |culter|
				tab2 = []
				tab1.each do |phrase|
					culter.cut(phrase) { tab2 << phrase }
				end
				tab1 = tab2
			end
			if block_given?
				yield tab1.shift
			else
				return tab1
			end
		end
	
		def name() @list.collect { |item| item.name }.join('') end
	end
		
end

