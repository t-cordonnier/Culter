begin
  require 'gtk3'
rescue LoadError
  require 'gtk2'  
end


module Culter end
module Culter::Ensis

  class Tester < Gtk::Window
    def initialize(culter)
      super()
      @culter = culter
      self.set_title('Segmentation rules tester')
      self.signal_connect('destroy') { Gtk.main_quit }
      @global_box = Gtk::VBox.new(false,0)
      self.add @global_box
      self.create_all_components
      self.set_default_size(300,500)
    end
    
    def start
      self.show_all
      Gtk.main
    end
    
    def add_pane(name, box)
      box1 = Gtk::Frame.new(name)
      @global_box.add(box1)
      box1.add(box)
      return box1
    end    
  end
  
  
  class TextBox < Gtk::Frame
    def initialize(culter,resultBox)
      super()      
      self.add(textBox = Gtk::TextView.new)
      textBox.buffer.signal_connect('changed') { resultBox.setContents(DebugLine.cut_debug(culter, textBox.buffer.text)) } 
    end
    
  end
  
  class ResultBox < Gtk::Frame
    def initialize
      super()
      @model = Gtk::ListStore.new(Integer, String,String)
      self.add(@view = Gtk::TreeView.new(@model))
      renderer = Gtk::CellRendererText.new
      renderer.set_property 'yalign', 0		# align to top
      @view.append_column Gtk::TreeViewColumn.new("Number",renderer)
      @view.append_column Gtk::TreeViewColumn.new("Segment",renderer)
      @view.append_column Gtk::TreeViewColumn.new("Rules",renderer)
      @view.columns[0].fixed_width = 50; @view.columns[0].add_attribute renderer, "text", 0
      @view.columns[1].fixed_width = 250; @view.columns[1].add_attribute renderer, "text", 1      
      @view.columns[2].fixed_width = 100; @view.columns[2].add_attribute renderer, "text", 2      
    end
    
    def setContents(split)
      @model.clear
      i = 0
      split.each do |segment|
	row = @model.append
	i = i + 1; row[0] = i
	row[1] = segment.phrase_with_mark("\u2316")
	row[2] = segment.rules.join("\r\n")	
      end
      @view.expand_all
    end    
  end


  
end

