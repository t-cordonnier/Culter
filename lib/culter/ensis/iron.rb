require 'System.Windows.Forms'


module Culter end
module Culter::Ensis

  class Tester < System::Windows::Forms::Form
    def initialize(culter)
      super()
      self.text = 'Segmentation Rules Tester'
      @culter = culter
      self.FormClosing { |s,e| System::Environment::Exit(0) }
      self.controls.add(@tab = System::Windows::Forms::TableLayoutPanel.new)
      @tab.AutoSize = true; @tab.Dock = System::Windows::Forms::DockStyle.Fill
      self.create_all_components
    self.width = 500; self.height = 300
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

