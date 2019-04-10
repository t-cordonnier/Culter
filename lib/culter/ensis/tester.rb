
if RUBY_PLATFORM == 'java' then
  require 'culter/ensis/java'
elsif RUBY_ENGINE == 'ironruby'
  require 'culter/ensis/iron'
else
  require 'culter/ensis/gtk2'
end

module Culter::Ensis

  class Tester
    def create_all_components
      @resultBox = ResultBox.new
      self.add_pane('Text to split', @textBox = TextBox.new(@culter,@resultBox))
      self.add_pane('Result', @resultBox)
    end
  end
  
end

