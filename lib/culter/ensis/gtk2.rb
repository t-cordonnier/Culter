begin
  require 'gtk3'
rescue LoadError
  require 'gtk2'  
end


module Culter end
module Culter::Ensis

  class EnsisWindow < Gtk::Window
    def initialize(culter)
      super()
      @global_box = Gtk::VBox.new(false,0)
      self.add @global_box
      if self.respond_to? 'create_menu' then self.create_menu end
      @culter = culter
      self.create_all_components
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
  
  # ------------------------------ Editor ------------------------

  class Editor < EnsisWindow
    def initialize(culter)
      super(culter)
      self.set_title('Segmentation Rules Editor' + (culter == nil ? '' : culter.name))
      self.signal_connect('destroy') { Gtk.main_quit }
    end
    
    def create_menu
      menubar = Gtk::MenuBar.new
      @global_box.pack_start( menubar, false, false, 0)
      menu1 = Gtk::MenuItem.new('Test')
      menubar.append menu1
      item1 = Gtk::MenuItem.new 'Test'
      item1.signal_connect("activate") { open_test }
      item2 = Gtk::MenuItem.new 'Quit'      
      item2.signal_connect("activate") { Gtk.main_quit }
      menu = Gtk::Menu.new
      menu.append item1; menu.append item2
      menu1.set_submenu menu
    end
    def input_dialog(question)
        dialog = Gtk::MessageDialog.new(self, Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
	     Gtk::MessageDialog::QUESTION,
             Gtk::MessageDialog::BUTTONS_OK_CANCEL,
             question)
        userEntry = Gtk::Entry.new
        userEntry.set_size_request(250,25)
        dialog.vbox.pack_end(userEntry, true, false, 0)
	dialog.show_all
	res = nil
	dialog.run do |response|
            if response == Gtk::Dialog::RESPONSE_OK
               res = userEntry.text
               dialog.destroy
	    else
               dialog.destroy
            end
	end
	return res
    end
  end
  
  class OptionsBox < Gtk::VBox
    def initialize(culter)
      super()
      self.add(@cascade = box('Cascade', culter, 'cascade'))
      self.add(formats = Gtk::HBox.new)
      formats.add(Gtk::Label.new('Format handles: '))
      formats.add(@fmtStart = box('Start',culter, 'formatHandle.start'))
      formats.add(@fmtEnd = box('End', culter,'formatHandle.end'))
      formats.add(@fmtIsolated = box('Isolated', culter,'formatHandle.isolated'))
    end
    
    def box(title, culter, field)
      box = Gtk::CheckButton.new(title)
      if field =~ /^(.+)\.(.+)/
          box.active = culter.send($1)[$2]
          box.signal_connect('toggled') { culter.send($1)[$2] = box.active? }          
      else
          box.active = culter.send(field)
          box.signal_connect('toggled') { culter.send(field + '=', box.active?) }
      end
      return box
    end
  end
  
  class RulesMappingBox < Gtk::TreeView
    def initialize(culter)
      super(@model = Gtk::ListStore.new(String,String))
      renderer = Gtk::CellRendererText.new
      renderer.set_property 'yalign', 0		# align to top
      append_column Gtk::TreeViewColumn.new("Expression",renderer)
      columns[0].add_attribute renderer, "text", 0
      append_column Gtk::TreeViewColumn.new("Name",renderer)
      columns[1].add_attribute renderer, "text", 1
      @model.clear
      culter.defaultMapRule.each do |mr|
	row = @model.append
	row[0] = mr.pattern.to_s
	row[1] = mr.rulename
      end
      self.expand_all    
    end
  end
  
  class TemplatesBox < Gtk::TreeView
    def initialize(culter)
      super(@model = Gtk::ListStore.new(String))
      renderer = Gtk::CellRendererText.new
      renderer.set_property 'yalign', 0		# align to top
      append_column Gtk::TreeViewColumn.new("Name",renderer)
      columns[0].add_attribute renderer, "text", 0
      @model.clear
      if culter.respond_to? 'ruleTemplates'
	 @map = culter.ruleTemplates
         culter.ruleTemplates.each do |name,rule| 
	   row = @model.append
	   row[0] = name
	 end
      else
	 @map = {}
      end
      self.expand_all    
    end    
  end

  # ------------------------------ Tester ------------------------
  
  class Tester < EnsisWindow
    def initialize(culter)
      super(culter)
      self.set_title('Segmentation Rules Tester - ' + culter.name)
      self.set_default_size(300,500)
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

