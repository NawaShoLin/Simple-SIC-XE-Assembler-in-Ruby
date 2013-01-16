#!usr/bin/ruby
$LOAD_PATH << "."
require 'assembler'
require 'test/unit'

class TestAssembler < Test::Unit::TestCase
 
  def test_comment
    assert Assembler.comment?(" \t. THIS IS A COMMENT")
    assert !Assembler.comment?("LABEL2 WORD 1")
  end
  
  def test_parse
    pairs = [
    ["COPY START 0", {:label => 'COPY', :operator => 'START', :operand => "0"}],
    ["CLOOP +JSUB RDREC", {:label => 'CLOOP', :operator => '+JSUB', :operand => "RDREC"}],
    ["\tEOF BYTE\tC'EOF'", {:label => 'EOF', :operator => 'BYTE', :operand => "C'EOF'"}],
    ["\tJEQ\tENDFIL", {:label => nil, :operator => 'JEQ', :operand => "ENDFIL"}],
    
    ]
    
    pairs.each do |a|
      assert_equal a[1], Assembler.parse(a[0])
    end
    
  end
  
  def test_read_byte_filed
    assert_equal "454F46", Assembler.read_byte_field("C'EOF'")
    assert_equal "05", Assembler.read_byte_field("X'05'")
    assert_raise( RuntimeError ) {  Assembler.read_byte_field("X'123'") }
    assert_raise( RuntimeError ) {  Assembler.read_byte_field("C''") }
    assert_raise( RuntimeError ) {  Assembler.read_byte_field("noCorX") }
  end
  
  def test_output_length
    pairs = [
      [3, {:operator => 'BYTE', :operand => "C'EOF'"}],
      [3, {:operator => 'JSUB', :operand => "WRREC"}],
      [4, {:operator => '+JSUB', :operand => "WRREC"}],
      [0, {:operator => 'START', :operand => "1234"}],
      [0x1000, {:operator => 'RESB', :operand => "4096"}],
      [6, {:operator => 'RESW', :operand => "2"}],
      [3, {:operator => 'LDA', :operand => "LENGTH"}],
      [3, {:operator => 'COMP', :operand => "#0"}],
      [3, {:operator => 'JEQ', :operand => "ENDFIL"}],
      [3, {:operator => 'J', :operand => "@RETADR"}]
    ]
    
    pairs.each do |a|
      assert_equal a[0], Assembler.output_length(a[1])
    end
    
    assert_raise( RuntimeError ) \
           {Assembler.output_length({:operator => 'XDDD', :operand => "1234"})}
    
  end
  
  def test_pass_one
   # asm = Assembler.new
   # asm.read_sourse(File.read "test.asm")
   # asm.pass_one
    #asm.print_table
  end
  
  def test_format4?
    assert Assembler.format4?("+JSUB")
    assert !Assembler.format4?("JEQ")
  end
  
  def test_operand_pair
    assert_equal ["BUFFER", "X"], Assembler.operand_pair("BUFFER , X")
    assert_equal ["X'F1'", nil], Assembler.operand_pair("X'F1'")
  end
  
  def test_opcode_to_binary
    assert_equal [0xB410, 2], Assembler.new.opcode_to_binary("CLEAR", "X", 0)
  end
  
  def test_pass_two
   # asm = Assembler.new
   # asm.read_sourse(File.read "test.asm")
   # asm.pass_one
    
   # assert_equal "LDB", Assembler.pure_op("LDB")
   # assert_equal asm.operand_value("RETADR"), 0x30
   # assert_equal asm.operand_value("#LENGTH"), 0x33
   # assert_equal [0x69202D,3], asm.opcode_to_binary("LDB", "#LENGTH", 0x03)
    
   # f = Assembler::Flag.new
   # f.format3
   # f.set_by_operand "#LENGTH"
    #assert_equal 0x12, f.to_binary
    #asm.pass_two true"
    #asm.print_table
  end
 
end