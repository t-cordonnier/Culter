require 'System.Windows.Forms'


module Culter end
module Culter::Ensis

  class EnsisWindow < System::Windows::Forms::Form
    def initialize(culter)
      super()
      @culter = culter
      self.controls.add(@tab = System::Windows::Forms::TableLayoutPanel.new)
      @tab.AutoSize = true; @tab.Dock = System::Windows::Forms::DockStyle.Fill
      self.create_all_components
    end
    
    def start
      self.start_position = System::Windows::Forms::FormStartPosition.center_screen
      self.show_dialog	  
    end
        
    def add_pane(name,box) 
      if box.respond_to? 'Text' then
         box.Text = name
         @tab.controls.add(box)
         box.Dock = System::Windows::Forms::DockStyle.Fill
      else
         group = System::Windows::Forms::GroupBox.new
         group.Text = name
         @tab.controls.add(group)
         group.controls.add(box)
         group.AutoSize = true; group.Dock = System::Windows::Forms::DockStyle.Fill
         box.Dock = System::Windows::Forms::DockStyle.Fill
      end
    end
  end
  
  # ------------------------------ Editor ------------------------

  class Editor < EnsisWindow
    def initialize(culter)
      super(culter)
      self.FormClosing { |s,e| System::Environment::Exit(0) }
      self.text = 'Segmentation Rules Editor' + (culter == nil ? '' : culter.name)
      self.menu = System::Windows::Forms::MainMenu.new
      menu1 = System::Windows::Forms::MenuItem.new('Test')
      self.menu.MenuItems.Add menu1
      
      item1 = System::Windows::Forms::MenuItem.new 'Test'
      item1.click { open_test }
      item2 = System::Windows::Forms::MenuItem.new 'Quit'      
      item2.click { System::Environment::Exit(0) }
      menu1.MenuItems.Add item1; menu1.MenuItems.Add item2
      
      self.width = 500; self.height = 400
    end
    def input_dialog(question) return SimpleInputDialog.new(question).prompt(); end
    
  end
  
  class SimpleInputDialog < System::Windows::Forms::Form
    def initialize(question)
      super()
      self.Width = 500; self.Height = 150
      self.Text = question
      self.FormBorderStyle = System::Windows::Forms::FormBorderStyle.FixedDialog
      self.StartPosition = System::Windows::Forms::FormStartPosition.CenterScreen
      textLabel = System::Windows::Forms::Label.new(); textLabel.Left = 50; textLabel.Top=20; textLabel.Width = 400; textLabel.Text = question
      @textBox = System::Windows::Forms::TextBox.new(); @textBox.Left = 50; @textBox.Top=50; @textBox.Width = 400 
      confirmation = System::Windows::Forms::Button.new(); confirmation.Text = "Ok" ; confirmation.DialogResult = System::Windows::Forms::DialogResult.OK 
      confirmation.Left = 350; confirmation.Width = 50; confirmation.Top = 90; 
      cancel = System::Windows::Forms::Button.new(); cancel.Text = "Cancel" ; cancel.DialogResult = System::Windows::Forms::DialogResult.Cancel 
      cancel.Left = 400; cancel.Width = 50; cancel.Top=90; 
      self.Controls.Add(textLabel); self.Controls.Add(@textBox)
      self.Controls.Add(confirmation); self.Controls.Add(cancel)
      self.AcceptButton = confirmation      
    end
                                     
    def prompt() 
      if self.ShowDialog() == System::Windows::Forms::DialogResult.OK then
         return @textBox.text 
      else 
	return nil
      end
    end
  end
                                     
  class OptionsBox < System::Windows::Forms::GroupBox
    def initialize(culter) end
  end
  
  class RulesMappingBox < System::Windows::Forms::GroupBox
    def initialize(culter)
      super
      self.controls.add(@view = System::Windows::Forms::DataGridView.new())
      @view.Dock = System::Windows::Forms::DockStyle.Fill
      @view.columns.add(colExpr = System::Windows::Forms::DataGridViewTextBoxColumn.new)
      @view.columns.add(colName = System::Windows::Forms::DataGridViewTextBoxColumn.new)
      colExpr.HeaderText = 'Expression'; colExpr.Width = 350
      colName.HeaderText = 'Name'; colName.Width = 60
      @view.Rows.Clear()
      culter.defaultMapRule.each do |mr|
        rowId = @view.Rows.Add
        @view.Rows[rowId].Cells[0].Value = mr.pattern.to_s
        @view.Rows[rowId].Cells[1].Value = mr.rulename
      end
    end    
  end
  
  class TemplatesBox < System::Windows::Forms::GroupBox
    def initialize(culter) end    
  end  
    
  # ------------------------------ Tester ------------------------
  
  class Tester < EnsisWindow
    def initialize(culter)
      super(culter)
      self.text = 'Segmentation Rules Tester - ' + culter.name
      self.width = 500; self.height = 300
    end
  end
  
  class TextBox < System::Windows::Forms::GroupBox
    def initialize(culter,resultBox)
      super()
      self.Controls.add(textBox = System::Windows::Forms::TextBox.new())
      textBox.multiline = true
      textBox.TextChanged { |s,e| resultBox.setContents(DebugLine.cut_debug(culter,textBox.Text.to_s)) } 
      textBox.AutoSize = true; textBox.Dock = System::Windows::Forms::DockStyle.Fill
    end
  end  
  
  class ResultBox < System::Windows::Forms::GroupBox
    def initialize
      super
      self.controls.add(@view = System::Windows::Forms::DataGridView.new())
      @view.Dock = System::Windows::Forms::DockStyle.Fill
      @view.columns.add(colId = System::Windows::Forms::DataGridViewTextBoxColumn.new)	  
      @view.columns.add(colSeg = System::Windows::Forms::DataGridViewTextBoxColumn.new)
      @view.columns.add(colRule = System::Windows::Forms::DataGridViewTextBoxColumn.new)
      colId.HeaderText = 'Id'; colId.Width = 50
      colSeg.HeaderText = 'Segment'; colSeg.Width = 350
      colRule.HeaderText = 'Rule'; colRule.Width = 100
      @view.ReadOnly = true
    end
    
    def setContents(split)
      @view.Rows.Clear()
      i = 0
      split.each do |segment|
        rowId = @view.Rows.Add
        i = i + 1; @view.Rows[rowId].Cells[0].Value = i
        @view.Rows[rowId].Cells[1].Value = segment.phrase_with_mark
        @view.Rows[rowId].Cells[2].Value = segment.rules[-1]	
      end
    end
  end

end

