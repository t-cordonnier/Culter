begin
  require 'gtk3'
rescue LoadError
  require 'gtk2'  
end


module Culter end
module Culter::Ensis

  class EnsisWindow < Gtk::Window
    def initialize()
      super()
      @global_box = Gtk::VBox.new(false,0)
      self.add @global_box
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
      super()
      @culter = culter
      self.set_title('Segmentation Rules Editor' + (culter == nil ? '' : culter.name))
      self.signal_connect('destroy') { Gtk.main_quit }
      menubar = Gtk::MenuBar.new
      @global_box.pack_start( menubar, false, false, 0)
      menu1 = Gtk::MenuItem.new('Test')
      menubar.append menu1
      item1 = Gtk::MenuItem.new 'Test'
      item1.signal_connect("activate") do
        dialog = Gtk::MessageDialog.new(self, Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
	     Gtk::MessageDialog::QUESTION,
             Gtk::MessageDialog::BUTTONS_OK_CANCEL,
             "Select language:")
        userEntry = Gtk::Entry.new
        userEntry.set_size_request(250,10)
        dialog.vbox.pack_end(userEntry, true, false, 0)
	dialog.show_all
	dialog.run do |response|
            if response == Gtk::Dialog::RESPONSE_OK
               segmenter = Culter::Args::get_segmenter(@culter, userEntry.text)
               tester = Culter::Ensis::Tester.new(segmenter)
               dialog.destroy
	       tester.start
	    else
               dialog.destroy
            end
	end        
      end
      item2 = Gtk::MenuItem.new 'Quit'      
      item2.signal_connect("activate") { Gtk.main_quit }
      menu = Gtk::Menu.new
      menu.append item1; menu.append item2
      menu1.set_submenu menu
    end
  end
  
  # ------------------------------ Tester ------------------------
  
  class Tester < EnsisWindow
    def initialize(culter)
      super()
      @culter = culter
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

