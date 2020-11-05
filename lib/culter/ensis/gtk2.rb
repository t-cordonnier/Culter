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
  
  class ButtonsViewBox < Gtk::HBox
    def initialize(window,culter)
      super()
      @window = window
      self.add(@view = create_view(culter))
      self.add(btnBox = Gtk::VBox.new)
      before_buttons.each { |btn| btnBox.add(btn) } 
      btnBox.add(@btnAdd = Gtk::Button.new('Add'))
      btnBox.add(@btnEdit = Gtk::Button.new('Edit'))
      @btnAdd.signal_connect('clicked') { action_add }
      @btnEdit.signal_connect('clicked') { action_edit }
      btnBox.add(btnRemove = Gtk::Button.new('Remove'))
      btnRemove.signal_connect('clicked') do 
        dialog = Gtk::MessageDialog.new(nil, Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
	     Gtk::MessageDialog::QUESTION,
             Gtk::MessageDialog::BUTTONS_OK_CANCEL,
             'Are you sure?')
	dialog.run do |response|
            if response == Gtk::Dialog::RESPONSE_OK then do_remove end
            dialog.destroy
	end
      end
      @selectedItem = nil; @btnEdit.sensitive = false; @view.selection.signal_connect('changed') { |s| @btnEdit.sensitive = true; @selectedItem = s.selected }      
    end
  end
  
  class RulesMappingView < Gtk::TreeView
    def initialize(culter)
      super(@model = Gtk::ListStore.new(String,String))
      renderer = Gtk::CellRendererText.new
      renderer.set_property 'yalign', 0		# align to top
      append_column Gtk::TreeViewColumn.new("Expression",renderer)
      columns[0].add_attribute renderer, "text", 0
      append_column Gtk::TreeViewColumn.new("Name",renderer)
      columns[1].add_attribute renderer, "text", 1
      @model.clear
      culter.defaultMapRule.each { |mr| add_to_view(mr) }
      self.expand_all    
    end
    def refresh_item(idx,mr)
	row = @model.append
	row[0] = mr.pattern.to_s
	row[1] = mr.rulename    
    end
    def add_to_view(mr) 
	row = @model.append
	row[0] = mr.pattern.to_s
	row[1] = mr.rulename
    end
  end
  
  class RulesMappingBox < ButtonsViewBox
    def initialize(window,culter)
      super(window,culter)
      @mapRule = culter.defaultMapRule
      @langRules = culter.langRules
    end
    def create_view(culter) return RulesMappingView.new(culter) end
    def before_buttons()
      btnUp = Gtk::Button.new('↑ Move up')
      btnDown = Gtk::Button.new('↓ Move down')
      return [ btnUp, btnDown ]
    end
    def do_remove() puts "OK" end
    def refresh_item(idx,mr) @view.refresh_item(idx,mr) end
    def add_to_view(mr) @view.add_to_view(mr) end
    def selectedIndex() @selectedItem.to_s.to_i end
  end
  
  class MappingEditDialog < Gtk::Dialog 
    def initialize(parent,langRules,maprule,mapping)
      super(mapping == nil ? 'New mapping' : 'Edit mapping', parent, Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT], [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])      
      vbox.add(panel1 = Gtk::HBox.new)
      panel1.add(Gtk::Label.new('Language (expression): '))
      panel1.add(@langBox = Gtk::Entry.new)
      vbox.add(panel2 = Gtk::HBox.new)
      panel2.add(@rbExisting = Gtk::RadioButton.new('Existing language rule: '))
      panel2.add(@cbExisting = Gtk::ComboBox.new())
      langRules.each { |k,v| @cbExisting.append_text(k) }
      panel2.add(@btnEditExisting = Gtk::Button.new('Edit'))
      vbox.add(panel3 = Gtk::HBox.new)      
      panel3.add(@rbNewMapping = Gtk::RadioButton.new('New language rule: '))
      panel3.add(@txtNewMappingName = Gtk::Entry.new)
      panel3.add(@btnEditNew = Gtk::Button.new('Edit'))
      @rbNewMapping.group = @rbExisting.group[0]
      @rbExisting.signal_connect('toggled') { @cbExisting.sensitive = @btnEditExisting.sensitive = true; @txtNewMappingName.sensitive = @btnEditNew.sensitive = false }
      @rbNewMapping.signal_connect('toggled') { @cbExisting.sensitive = @btnEditExisting.sensitive = false; @txtNewMappingName.sensitive = @btnEditNew.sensitive = true }
      if mapping != nil then
	@mapping = mapping
	@rbExisting.active = true; # cbExisting.selectedItem = mapping.rulename
	@cbExisting.sensitive = @btnEditExisting.sensitive = true; @txtNewMappingName.sensitive = @btnEditNew.sensitive = false
	@langBox.text = mapping.pattern.to_s	
      else
	@rbNewMapping.active = true
	@cbExisting.sensitive = @btnEditExisting.sensitive = false; @txtNewMappingName.sensitive = @btnEditNew.sensitive = true
      end
    end
    
    attr_reader :mapping
    def action!()
        show_all
	run do |response|
            if response == Gtk::Dialog::RESPONSE_ACCEPT then 
	       if @rbNewMapping.active? then
	          @mapping = Culter::SRX::LangMap.new(Regexp.new(@langBox.text), @txtNewMappingName.text)
	       else
	           @mapping = Culter::SRX::LangMap.new(Regexp.new(@langBox.text), @cbExisting.active_text)	  
	       end
	    else
	      @mapping = nil
	    end
            destroy
	end    
    end
  end  
  
  class TemplatesView < Gtk::TreeView
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
    attr_reader :map
  end  

  class TemplatesBox < ButtonsViewBox
    def initialize(window,culter)
      super(window,culter)
      @map = @view.map
    end
    def add_to_view(rule) row = @view.model.append; row[0] = rule.ruleName; end
    def create_view(culter) return TemplatesView.new(culter) end
    def before_buttons() [] end
    def do_remove() puts "OK" end
    def selectedItem() @selectedItem[0] end
  end
  
  class RuleEditDialog < Gtk::Dialog    
    def initialize(window,rule)
      super(rule == nil ? 'New rule' : 'Edit rule', window, Gtk::Dialog::MODAL | Gtk::Dialog::DESTROY_WITH_PARENT,
             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT], [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT])      
      vbox.add(panel1 = Gtk::HBox.new)
      panel1.add(@rbBreak = Gtk::RadioButton.new('Break'))
      panel1.add(@rbException = Gtk::RadioButton.new('Exception')) 
      @rbException.group = @rbBreak.group[0]
      vbox.add(panel2 = Gtk::HBox.new)
      panel2.add(Gtk::Label.new('Before: '))
      panel2.add(@beforeBox = Gtk::Entry.new)
      vbox.add(panel3 = Gtk::HBox.new)
      panel3.add(Gtk::Label.new('After: '))
      panel3.add(@afterBox = Gtk::Entry.new)
      vbox.add(panel4 = Gtk::HBox.new)
      panel4.add(Gtk::Label.new('Rule name: '))
      panel4.add(@nameBox = Gtk::Entry.new)
      if rule != nil then
	@rule = rule
	@nameBox.sensitive = false; if rule.respond_to? 'name' then @nameBox.text = rule.name else @rule.ruleName end
	if rule.respond_to? 'rewriteRule' then rule = rule.rewriteRule end
	if rule.break then @rbBreak.active = true else @rbException.active = true end 
	@beforeBox.text = rule.before; @afterBox.text = rule.after
      else
	@rbBreak.active = true
	#okBtn.sensitive = nameBox.text.length > 0; nameBox.signal_connect('changed') { okBtn.sensitive = nameBox.text.length > 0 }
      end
    end
  
    attr_reader :rule    
    def action!()
        show_all
	run do |response|
            if response == Gtk::Dialog::RESPONSE_ACCEPT then 
	       @rule = Culter::SRX::Rule.new(@rbBreak.active?, @nameBox.text)
	       @rule.before = @beforeBox.text; @rule.after = @afterBox.text
	    else
	      @rule = nil
	    end
            destroy
	end    
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

