require 'java'


module Culter end
module Culter::Ensis

  class EnsisWindow < javax.swing.JFrame
    def initialize(title)
      super(title)
      self.contentPane.setLayout(javax.swing.BoxLayout.new(self.contentPane, javax.swing.BoxLayout::Y_AXIS))      
      self.create_all_components
    end
    
    def start
      self.pack; self.show
    end
        
    def add_pane(name,box) 
      box.setBorder(javax.swing.BorderFactory.createTitledBorder(name))
      self.contentPane.add(box)
    end
  end
  
  # ------------------------------ Editor ------------------------

  class Editor < EnsisWindow
    def initialize(culter)
      super('Segmentation Rules Editor' + (culter == nil ? '' : culter.name))
      @culter = culter
      self.jMenuBar = javax.swing.JMenuBar.new
      menu1 = javax.swing.JMenu.new('Test')
      self.jMenuBar.add menu1
      item1 = javax.swing.JMenuItem.new 'Test'
      item1.addActionListener { |ev| open_test }
      item2 = javax.swing.JMenuItem.new 'Quit'      
      item2.addActionListener { |ev| java.lang.System.exit(0) }
      menu1.add item1; menu1.add item2
      self.setDefaultCloseOperation(javax.swing.JFrame::EXIT_ON_CLOSE);
    end
    def input_dialog(question) return javax.swing.JOptionPane.showInputDialog(self, question); end
  end
  
  class OptionsBox < javax.swing.JPanel
    
  end
  
  class RulesMappingBox < javax.swing.JPanel
    
  end
  
  class TemplatesBox < javax.swing.JPanel
    
  end  
  
  # ------------------------------ Tester ------------------------
  
  class Tester < EnsisWindow
    def initialize(culter)
      super('Segmentation Rules Tester - ' + culter.name)
      @culter = culter
      self.setDefaultCloseOperation(javax.swing.JFrame::DISPOSE_ON_CLOSE);
    end
  end
  
  class MyChangeListener
    include javax.swing.event.DocumentListener
    def initialize(textBox,culter,resultBox)
       @textBox = textBox; @culter = culter; @resultBox = resultBox  
    end
    
    def changeUpdate(ev) end
    def insertUpdate(ev) @resultBox.setContents(DebugLine.cut_debug(@culter,@textBox.text)); end
    def removeUpdate(ev) @resultBox.setContents(DebugLine.cut_debug(@culter,@textBox.text)); end
  end
  
  class TextBox < javax.swing.JPanel
    def initialize(culter,resultBox)
      super()
      self.layout = java.awt.BorderLayout.new
      self.add(text = javax.swing.JTextArea.new, java.awt.BorderLayout::CENTER)
      text.document.addDocumentListener(MyChangeListener.new(text,culter,resultBox))
      text.preferredSize = java.awt.Dimension.new(500,100)
      text.lineWrap = text.wrapStyleWord = true
    end    
  end
  
  class MyTableModel < javax.swing.table.AbstractTableModel
    def initialize() 
      @split = Array.new
    end
    
    def contents=(ct) @split = ct end
    
    def getColumnCount() 3 end
    def getRowCount() @split.count end
    def getValueAt(row,col) 
      if col == 0 then return row + 1 end
      if col == 1 then 
	return @split[row].phrase_with_mark 
      end
      if col == 2 then 
	return @split[row].rules[-1] 
      end
      return ""
    end
  end
  
  class ResultBox < javax.swing.JPanel
    def initialize
      super
      self.add(@view = javax.swing.JTable.new(), java.awt.BorderLayout::CENTER)
      size = @view.preferredSize; size.width = 500; size.height = 100; @view.preferredSize = size
      @view.model = MyTableModel.new()
      @view.columnModel.getColumn(0).preferredWidth = 50
      @view.columnModel.getColumn(1).preferredWidth = 350
      @view.columnModel.getColumn(2).preferredWidth = 100
    end
    
    def setContents(split)
       @view.model.contents = split
       repaint
    end
  end

end

