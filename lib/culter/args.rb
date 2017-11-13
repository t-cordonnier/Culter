module Culter end
module Culter::Args

  def self.set_verbosity!
    $CULTER_VERBOSE = 0 
    if not(ARGV.empty?) and (ARGV[0] =~ /-v/) then 
      while ARGV[0] =~ /-(v+)/ do  $CULTER_VERBOSE = $CULTER_VERBOSE + $1.length; ARGV.shift ; end
    end
  end
  
  def self.get_doc
    if ARGV.empty?
      require 'culter/simple'
      if $CULTER_VERBOSE > 0 then puts "Using simple segmenter" end
      return Culter::Simple.new
    else
      return load_file(ARGV.shift)
    end
  end
  
  def self.load_file(data)      
    if data =~ /\.srx$/i
      require 'culter/srx'
      return Culter::SRX::SrxDocument.new(data)
    elsif data =~ /\.cscx$/i
      require 'culter/cscx'
      return Culter::CSC::XML::CscxDocument.new(data)
    elsif data =~ /\.cscy$/
      require 'culter/cscy'
      return Culter::CSC::YML::CscyDocument.new(data)		
    elsif data =~ /\.csex$/i
      require 'culter/csex'
      doc = Culter::CSEX::CsexDocument.new(data)
    else
      raise ArgumentError.new("#{data} is not a valid segmentation format")	
    end
  end
  
  def self.get_segmenter(doc, data)
    if data =~ /^(.+):(.+)$/
      culter = doc.segmenter($2,$1)
    elsif data != nil
      culter = doc.segmenter(data)
    else
      raise ArgumentError.new("Missing language")
    end
    if $CULTER_VERBOSE > 0 then puts "#{culter.rulesCount} rules found." end
    return culter
  end
  
end
