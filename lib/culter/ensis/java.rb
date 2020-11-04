require 'java'


module Culter end
module Culter::Ensis

  class EnsisWindow < javax.swing.JFrame
    def initialize(title)
      super(title)
      self.contentPane.setLayout(javax.swing.BoxLayout.new(self.contentPane, javax.swing.BoxLayout::Y_AXIS))      
      # @culter = culter ===> error, why?!?
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
      self.contentPane.components.each { |item| item.post_init(culter) }
    end
    def input_dialog(question) return javax.swing.JOptionPane.showInputDialog(self, question); end
  end
  
  class OptionsBox < javax.swing.Box
    def initialize(culter)
      super(javax.swing.BoxLayout::Y_AXIS)
      self.add(@cascade = box('Cascade', culter, 'cascade'))
      self.add(formats = javax.swing.Box.new(javax.swing.BoxLayout::X_AXIS))
      formats.add(javax.swing.JLabel.new('Format handles: '))
      formats.add(@fmtStart = box('Start',culter, 'formatHandle.start'))
      formats.add(@fmtEnd = box('End', culter,'formatHandle.end'))
      formats.add(@fmtIsolated = box('Isolated', culter,'formatHandle.isolated'))
    end
    
    def post_init(culter)
      add_listener(@cascade,'cascade',culter)
      add_listener(@fmtStart,'formatHandle.start',culter)
      add_listener(@fmtEnd,'formatHandle.end',culter)
      add_listener(@fmtIsolated,'formatHandle.isolated',culter)
    end    
      
    def add_listener(box,field,culter)  
      if field =~ /^(.+)\.(.+)/
          box.selected = culter.send($1)[$2]
          box.addActionListener { |ev| culter.send($1)[$2] = box.selected? }          
      else
          box.selected = culter.send(field)
          box.addActionListener { |ev| culter.send(field + '=', box.selected?) }
      end
    end
    
    def box(title, culter, field)
      box = javax.swing.JCheckBox.new(title)
      return box
    end
    
  end

  class ButtonsViewBox < javax.swing.JPanel
    def initialize(culter)
      super()
      self.layout = java.awt.BorderLayout.new
      self.add(@view = create_view(culter), java.awt.BorderLayout::CENTER)
      self.add(btnBox = javax.swing.Box.new(javax.swing.BoxLayout::Y_AXIS), java.awt.BorderLayout::EAST)
      before_buttons.each { |btn| btnBox.add(btn) } 
      btnBox.add(btnAdd = javax.swing.JButton.new('Add'))
      btnBox.add(btnEdit = javax.swing.JButton.new('Edit'))
      btnBox.add(btnRemove = javax.swing.JButton.new('Remove'))
      btnRemove.addActionListener do |ev|
	if javax.swing.JOptionPane.showConfirmDialog(nil, 'Are you sure?', 'Are you sure?', javax.swing.JOptionPane::YES_NO_OPTION) == javax.swing.JOptionPane::YES_OPTION then
            do_remove
	end
      end
    end
  end
  
  class RulesMappingBox < ButtonsViewBox
    def initialize(culter)
      super
      @view.model = javax.swing.DefaultListModel.new
    end
    
    def post_init(culter)  
      culter.defaultMapRule.each do |mr| @view.model.addElement("#{mr.pattern.to_s} => #{mr.rulename}") end
      @mapRule = culter.defaultMapRule
    end
    def create_view(culter) return javax.swing.JList.new end
    def before_buttons()
      btnUp = javax.swing.JButton.new('↑ Move up')
      btnDown = javax.swing.JButton.new('↓ Move down')
      return [ btnUp, btnDown ]
    end
    def do_remove()
       @mapRule.delete_at(@view.selectedIndex)
       @view.model.remove(@view.selectedIndex)
    end    
  end
  
  class TemplatesBox < ButtonsViewBox
    def initialize(culter)
      super
      @view.model = javax.swing.DefaultListModel.new
    end
    
    def post_init(culter)
      if culter.respond_to? 'ruleTemplates'
	 @map = culter.ruleTemplates
         culter.ruleTemplates.each do |name,rule| @view.model.addElement(name) end
      else
	 @map = {}
      end
    end
    def create_view(culter) return javax.swing.JList.new end
    def before_buttons() [] end
    def do_remove()
       @map.delete(@view.model.elementAt(@view.selectedIndex))
       @view.model.remove(@view.selectedIndex)
    end
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

