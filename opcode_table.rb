#!usr/bin/ruby

OPCODE_TABLE = {
  "CLEAR" => {:opcode => 0xb4, :format => 2},
  "COMP"  => {:opcode => 0x28, :format => 3},
  "COMPR" => {:opcode => 0xa0, :format => 2},
  "J"     => {:opcode => 0x3c, :format => 3},
  "JEQ"   => {:opcode => 0x30, :format => 3},
  "JLT"   => {:opcode => 0x38, :format => 3},
  "JSUB"  => {:opcode => 0x48, :format => 3},
  "LDA"   => {:opcode => 0x00, :format => 3},
  "LDB"   => {:opcode => 0x68, :format => 3},
  "LDCH"  => {:opcode => 0x50, :format => 3},
  "LDT"   => {:opcode => 0x74, :format => 3},
  "RD"    => {:opcode => 0xd8, :format => 3},
  "RSUB"  => {:opcode => 0x4c, :format => 3},
  "STA"   => {:opcode => 0x0c, :format => 3},
  "STCH"  => {:opcode => 0x54, :format => 3},
  "STL"   => {:opcode => 0x14, :format => 3},
  "STX"   => {:opcode => 0x10, :format => 3},
  "TD"    => {:opcode => 0xe0, :format => 3},
  "TIXR"  => {:opcode => 0xb8, :format => 2},
  "WD"    => {:opcode => 0xdc, :format => 3}
}

FAKE_OPS = ["START","END","BYTE","WORD","RESB","RESW", "BASE"]

def paser_regex
  ops = (OPCODE_TABLE.keys + FAKE_OPS).sort_by{|x| -x.length}
  operator =  ops.join('|')
  operator = "(?<operator>\\+?(#{operator}))"
  label    = "^\\s*((?<label>\\w+)\\s+)?"
  operand  = "(\\S+(\\s*,\\s*\\S+)?)"
  operand  = "(\\s+(?<operand>#{operand}))?\\s*$"
  return Regexp.new(label+operator+operand, Regexp::IGNORECASE)
end

