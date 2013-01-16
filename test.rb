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
    ["\tJEQ\tENDFIL", {:label => nil, :operator => 'JEQ', :operand => "ENDFIL"}]  
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
    asm = Assembler.new
    asm.read_sourse(File.read "normalsicxe.asm")
    asm.pass_one
    asm.print_table
  end
 
end