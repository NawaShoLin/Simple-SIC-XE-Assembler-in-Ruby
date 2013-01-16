#!usr/bin/ruby
$LOAD_PATH << "."
require 'opcode_table'

class Assembler
  
  OP_TABLE = OPCODE_TABLE
  OP_REG = paser_regex
  
  def initialize
    @lines = []
    @symbols = {}
    @begin_loc = 0
    @title = nil
  end
  
  def read_sourse(sourse)
    sourse_lines = sourse.split("\n").map{|x| x.chomp}
    sourse_lines.delete_if{|x| Assembler.comment? x}
    @lines = sourse_lines.map{|x| Assembler.parse x}
  end # end read_file

  def pass_one
    loc_ctr = 0
    
    if @lines.first[:operator] == "START"
      @begin_loc = @lines.first[:operand].to_i
      raise "no operand at START line" if not @begin_loc
      loc_ctr = @begin_loc
    end    
    
    @lines.each do |line|
      if line[:label]
        label = line[:label]
        raise "more than 2 same labels: #{label}" if @symbols.has_key? label
        @symbols[label] = loc_ctr
      end
      line[:loc] = loc_ctr
      loc_ctr += Assembler.output_length line
    end
  end  # end pass_one
  
  def pass_two
    @title = @lines.first[:label] if @lines.first[:operator] == "START"
    
    @lines.each do |line|
      operator, operand, loc = line[:operator], line[:operand], line[:loc]
      if OP_TABLE.has_key? operator
      else
      end
    end
    
  end
  
  # ---- ---- debuging method ---- ----
  def label_loc label
    @symbols[label]
  end
  
  # ---- ---- helper functions ---- ----
  private
  
  def self.comment? (line)
    !! (/^\s*\..*/.match line)
  end
  
  # return {:label => nil/String, :operator => String, :operand => nil/String}
  def self.parse(line)
    match_result = OP_REG.match line
    raise "operator unfined in line:\n #{line}" if not match_result
    result = {:label => nil, :operator => nil, :operand => nil}
    
    result.each_key do |k|
      value = match_result[k]
      if value
        value = value.upcase #.gsub(/\s/, "") 
        result[k] = value unless value.empty?
      end
    end
    
    result
  end # end parse
  
  def self.read_byte_field byte_f
    match_result = /(?<type>C|c|X|x|)\s*'(?<msg>.+)'/.match byte_f
    raise "No match at BYTE field : #{byte_f}" if not match_result
    
    type = match_result[:type].upcase
    msg  = match_result[:msg]
    result = ""
    if type == 'C'
      msg.each_byte do |b|
        s = b.to_s(16)
        s = "0" + s if s.length == 1 
        result << s 
      end
    else
      raise "Error byte field length" if msg.length % 2 != 0
      result = msg
    end
    
    result.upcase
  end
  
  def self.output_length line
    operator = line[:operator].gsub("+", "")
    length = nil
      
    if OP_TABLE.has_key? operator
      length = OP_TABLE[operator][:format]
      
      # format 4
      if line[:operator][0] == "+"
        raise "plus symbol in format 1/2" if OP_TABLE[operator][:format] <= 2
        length = 4
      end
      
    else
      operator = line[:operator]
      raise "unknow operator: #{operator}" if not FAKE_OPS.index(operator)
      case operator
      when "WORD" then length = 3
      when "RESB" then length = line[:operand].to_i
      when "RESW" then length = line[:operand].to_i * 3
      when "BYTE"
        length = Assembler.read_byte_field(line[:operand]).length / 2
      else length = 0        
      end
    end # end if-else 
          
    length 
  end # end output_length
  
  def self.format4? operator
    /\+\S+/.match operator
  end
  
  def opcode_to_binary operator, operand
    
  end
  
end
