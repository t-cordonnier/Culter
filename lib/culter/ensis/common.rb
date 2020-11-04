
if RUBY_PLATFORM == 'java' then
  require 'culter/ensis/java'
elsif RUBY_ENGINE == 'ironruby'
  require 'culter/ensis/iron'
else
  require 'culter/ensis/gtk2'
end

module Culter::Ensis

  class DebugLine
    def self.cut_debug(culter,segment)
      if not culter.respond_to? 'cut_debug' then
	return culter.cut(segment).map { |item| DebugLine.new("#{item}<A:Simple:") } 
      end
      return culter.cut_debug(segment).split(':true>').map { |item| DebugLine.new(item) }
    end
    def initialize(item)
      @rules = Array.new
      item.gsub!(/<([^>]+):([^>]+):(true|false)>/) do
	@rules << $2
	if $3 == 'true' then '' else '<!>' end
      end
      @phrase = item
      item.sub!(/<([^>]+)$/) { @rules << $2; '' }
    end
    def phrase_with_mark(mark = '<!>')
      if mark == '<!>' then return @phrase else return @phrase.gsub('<!>',mark) end
    end
    attr_reader :rules
  end
  
  class Tester
    def create_all_components
      @resultBox = ResultBox.new
      self.add_pane('Text to split', @textBox = TextBox.new(@culter,@resultBox))
      self.add_pane('Result', @resultBox)
    end
  end

  class Editor
    def create_all_components
      self.add_pane('Options', OptionsBox.new(@culter))
      self.add_pane('Rules Mapping', RulesMappingBox.new(self,@culter))
      self.add_pane('Rule templates', TemplatesBox.new(self,@culter))
    end
    def open_test
      lang = input_dialog('Select Language (ISO-639 code): ')
      if lang != nil then 
	Culter::Ensis::Tester.new(Culter::Args::get_segmenter(@culter, lang)).start 
      end
    end
  end
  
  class TemplatesBox
    def action_add 
      dial = RuleEditDialog.new(@window,nil); dial.action!
      if dial.rule != nil then 
	add_to_view(dial.rule)
	@map[dial.rule.ruleName] = Culter::CSC::RuleTemplate.new(dial.rule.ruleName)
	@map[dial.rule.ruleName].rewriteRule = dial.rule
      end
    end
    def action_edit 
      dial = RuleEditDialog.new(@window,@map[self.selectedItem]); dial.action!
      if dial.rule != nil then 
	@map[dial.rule.ruleName].rewriteRule = dial.rule
      end
    end
  end
end

