#! /usr/bin/env ruby 

$LOAD_PATH << "#{File.dirname(__FILE__)}/../lib"                # For non-standard installation
require 'culter/srx'

require './test-function.rb'

srxAsString = <<'EOF'
<srx version='2.0' xmlns='http://www.lisa.org/srx20'>
	<header cascade="yes" />
	<body>
		<languagerules>
			<languagerule languagerulename='English'>
				<rule break="no">
					<beforebreak>\b(Mrs?)\.</beforebreak>
					<afterbreak>\s</afterbreak>
				</rule>
			</languagerule>
			<languagerule languagerulename='Français'>
				<rule break="no">
					<beforebreak>\b(Mr|Mmes?|Mlles?|n°s|approx|c.-à-d|chap|coeff|coll|div|fig)\.</beforebreak>
					<afterbreak>\s</afterbreak>
				</rule>
			</languagerule>
			<languagerule languagerulename='All'>
				<rule break="yes">
					<beforebreak>[\.\?\!]</beforebreak>
					<afterbreak>\s\P{Lower}</afterbreak>
				</rule>
			</languagerule>
		</languagerules>
		<maprules>
			<languagemap languagepattern='[eE][nN]' languagerulename='English' />
			<languagemap languagepattern='[fF][rR]' languagerulename='Français' />
			<languagemap languagepattern='.+' languagerulename='All' />
		</maprules>
	</body>
</srx>
EOF
culter = Culter::SRX::SrxDocument.new srxAsString

line = "Here is Mrs. Untel. She came here! All fine."

# 	1. Test that this phrase segments correctly with "en" as language

test "en", culter.segmenter('en').cut(line), [
	"Here is Mrs. Untel.",			# Exception for Mrs.
	" She came here!",
	" All fine."
]

# 	2. Test that if language = "fr", abbreviations don't work but other cuts work correctly

test "fr", culter.segmenter('fr').cut(line), [
	"Here is Mrs.", " Untel.",		# Exception for Mrs. does not work (not in language 'fr')
	" She came here!",
	" All fine."
]

