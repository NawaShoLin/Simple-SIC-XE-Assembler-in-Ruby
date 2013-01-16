#!usr/bin/ruby
$LOAD_PATH << "."
require 'asm_const_table'

class Assembler
  
  OP_TABLE = OPCODE_TABLE
  OP_REG = paser_regex
  
  def initialize
    @lines = []
    @symbols = {}
    @begin_loc = 0
    @title = nil
    @base = nil
    @writer = Writer.new
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
  
  def pass_two debug = nil
    @title = @lines.first[:label] if @lines.first[:operator] == "START"
    @title = "NONE" if not @title
    if @title
      @writer.write_title @title, @lines.first[:operand].to_i
    else
      @title = "NONE"
      @writer.write_title @title, 0
    end
    
    
    
    @lines.each do |line|
      puts "#{line[:loc]}\t#{line[:operator]}\t#{line[:operand]}" if debug ####
      
      operator, operand, loc = line[:operator], line[:operand], line[:loc]
      output = nil
      if OP_TABLE.has_key? operator.match(/\+?(\w+)/)[1]
        bin, format = opcode_to_binary(operator, operand, loc)
        puts bin.to_s(16) if debug ####
        @writer.write loc, bin, nil, :format => format
      elsif FAKE_OPS.index operator
        case operator
        #when "START"
        when "END"
          @writer.end
          return
        when "BASE"
          @base = operand_value operand
        when "BYTE"
          @writer.write(loc, nil, Assembler.read_byte_field(operand))
        else
          # do nothing
        end
      else
        raise "unknown operator : #{operator}"
      end
    end
    
  end
  
  def print s
    @writer.print s
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
  
  def self.operand_pair operand # TO DO : C','
    a,b = operand.split(/\s*,\s*/)
    return a,b
  end
  
  def operand_value operand
    operand, = Assembler.operand_pair operand
    operand  = operand.match(/(#|@|)?(?<operand>\w+)/)[:operand]
    if operand.match(/^\d+$/)
      return operand.to_i
    elsif @symbols.has_key? operand
      return @symbols[operand]
    else
      raise "err at operand_value : unknown operand : #{operand}"
    end
  end
  
  public #testing
  def opcode_to_binary operator, operand, pc
    p_op = operator.match(/\+?(\w+)/)[1]
    op = OP_TABLE[p_op][:opcode]
    flags = Flag.new
    
    if OP_TABLE[p_op][:format] == 2
      r1, r2 = Assembler.operand_pair operand
      r1 = (r1 && REG_TABLE[r1]) || 0
      r2 = (r2 && REG_TABLE[r2]) || 0
      return (op << 8) + (r1 << 4) + r2, 2
      
    elsif Assembler.format4? operator
      flags.format4
      flags.set_by_operand operand    
      @writer.add_m pc if not flags.imm_num?
      return (op << 26) + (flags.to_binary << 20) + operand_value(operand), 4
      
    else # format 3
      flags.format3
      flags.set_by_operand operand
      
      if flags.imm_num?
        return (op << 18) + (flags.to_binary << 12) + operand_value(operand), 3
        
      elsif operand
        ta = operand_value(operand) 
        if pc - 2048 <= ta and pc + 2047 >= ta
          flags.pc_relative
          disp = ta - pc
          disp = (1<<12) + disp if disp < 0
          return (op << 18) + (flags.to_binary << 12) + disp, 3
        elsif @base && (@base <= ta) &&  (ta <= @base + 4095)
          flags.base_relative
          return (op << 18) + (flags.to_binary << 12) + ta - @base, 3
        else 
          raise "operand too large"
        end
        
      else
        return (op << 18), 3
      end
    end
  end
  
end

class Assembler
  class Flag
    def initialize
      @flag = {}
    end
    
    def base_relative
      @flag[:b], @flag[:p] = 1, 0
    end
    
    def pc_relative
      @flag[:b], @flag[:p] = 0, 1
    end
    
    def format3
      @flag[:e] = 0
    end
    
    def format4
      @flag[:b], @flag[:p], @flag[:e] = 0, 0, 1
    end
    
    def direct;  @flag[:x] = 0; end;
    def indexed; @flag[:x] = 1; end;
    
    def immediate_addr # #
      @flag[:i], @flag[:n] = 1, 0
    end
    
    def indirect_addr # @
      @flag[:i], @flag[:n] = 1, 0
    end
    
    def simple_addr
      @flag[:i], @flag[:n] = 1, 1
    end
    
    def imm_num
      immediate_addr
      @flag[:b] = @flag[:p] = 0
    end
    
    def imm_num?
      @flag[:i] == 1 and @flag[:n] == 0 and @flag[:b] == 0 and @flag[:p] == 0
    end
    
    def set_by_operand operand
      if not operand
        simple_addr
        direct
        @flag[:b] = @flag[:p] = 0
        return
      end
      
      a, b = Assembler.operand_pair operand
      if b
        if b.upcase == 'X'
          self.indexed
        else
          raise "OPERAND format err at Falg::set_by_operand: *, ? "
        end
      else
        self.direct
      end
      
      case a[0]
      when '#'
        if a[1..-1].match(/^\d+$/)
          self.imm_num
        else
          self.immediate_addr
        end
      when '@'
        self.indirect_addr
      else
        self.simple_addr
      end
    end
    
    def to_binary
      keys = [:n, :i, :x, :b, :p, :e]
      result = 0
      keys.each do |k|
        raise "Flag #{k} undefined." if not @flag[k]
        result <<= 1
        result += @flag[k]
      end
      result
    end
    
  end
  
  
  class Writer
    def initialize
      @doc = []
      @title = ""
      @now_loc = nil
      @start_loc = nil
      @ms = []
      @f_exe = nil
    end
    
    def print s
      s.puts @title
      @doc.each{|t| s.puts t.upcase}
      @ms.each{|m| s.puts m.upcase}
      
      e = @f_exe.to_s(16).upcase
      e = ("0" * (6-e.length)) + e
      s.puts "E#{e}"
    end
    
    def write_title title, start_loc
      @start_loc = start_loc
      title = title[0..5] if title.length > 6
      title += " " * (6 - title.length) if title.length < 6
      start_loc = start_loc.to_s(16)
      start_loc = ("0" * (6-start_loc.length)) + start_loc if start_loc.length < 6
      @title = "H#{title}#{start_loc}"
    end
    
    def end
      t_loc = (@now_loc - @start_loc).to_s(16)
      t_loc = ("0" * (6-t_loc.length)) + t_loc if t_loc.length < 6
      @title << t_loc
    end
    
    def add_m loc
      t_loc = (loc+1).to_s(16)
      t_loc = ("0" * (6-t_loc.length)) + t_loc if t_loc.length < 6
      @ms << "M#{t_loc}05"
    end
    
    def write(loc, bin = nil, str = nil, option = {})
      def add_len line, len_plus
        len = (line[7..8].to_i + len_plus).to_s
        len = "0" + len if len.length == 1
        line[7..8] = len
      end
      
      @now_loc = @start_loc if not @now_loc
      
      if bin
        @f_exe = loc if not @f_exe
        str = bin.to_s(16)
        if option[:format] && option[:format] * 2 > str.length
          str = ("0" * (option[:format] * 2 - str.length)) + str
        end
      end
      
      if !@doc.last or loc != @now_loc or @doc.last.length + str.length > 60
        t_loc = loc.to_s(16)
        t_loc = ("0" * (6-t_loc.length)) + t_loc if t_loc.length < 6
        @doc << "T#{t_loc}00"
      end
      
      add_len @doc.last, str.length/2
      @doc.last << str
      @now_loc = loc + str.length/2      
      
    end
    
  end
end
