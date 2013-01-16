#!usr/bin/ruby
$LOAD_PATH << "."
require 'assembler'

input_file  = ARGV[0]
output_file = ARGV[1]

asm = Assembler.new
asm.read_sourse(File.read(input_file))
asm.pass_one
asm.pass_two
asm.print File.open(output_file, "w")
