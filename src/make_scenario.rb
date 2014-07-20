#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------
require 'pp'
require_relative "../Dummy_Plug/tools/Dummy_Plug/ScenarioWriter/axi4"
require_relative "../Dummy_Plug/tools/Dummy_Plug/ScenarioWriter/number-generater"

class ScenarioGenerater
  def initialize(name, axi4_data_width, offset_width)
    @name            = name
    @axi4_addr_width = 32
    @axi4_data_width = axi4_data_width
    @axi4_data_size  = (Math.log2(@axi4_data_width/8)).to_i
    @max_xfer_size   = 16*(@axi4_data_width/8)
    @offset_width    = offset_width
    @no              = 0
    @id              = 0
    @master          = Dummy_Plug::ScenarioWriter::AXI4::Master.new("MASTER", {
                         :ID            => 0,
                         :ID_WIDTH      => 1,
                         :ADDR_WIDTH    => @axi4_addr_width,
                         :DATA_WIDTH    => @axi4_data_width,
                         :MAX_TRAN_SIZE => @max_xfer_size  
                       })
    @data            = (1..(2**@offset_width)).collect{rand(256)}
  end

  def generate_init_ram_0(file_name)
    io  = open(file_name, "w")
    pos   = 0
    bytes = @axi4_data_width/8
    data  = Array.new(bytes, 0)
    while pos < @data.size-1 do
      data.each{|u8| io.printf("%02x", u8)}
      io.puts 
      pos += bytes
    end
    io.close
  end

  def generate_init_ram_2(file_name)
    io  = open(file_name, "w")
    pos   = 0
    bytes = @axi4_data_width/8
    while pos < @data.size-1 do
      @data[pos..pos+bytes-1].reverse.each{|u8| io.printf("%02x", u8)}
      io.puts 
      pos += bytes
    end
    io.close
  end

  def generate_scenario_2(file_name)
    io = open(file_name, "w")
    title = @name.to_s + ".2"
    xfer_pattern = Dummy_Plug::ScenarioWriter::RandomNumberGenerater.new([0,0,0,0,0,1,2,3])
    io.print "---\n"
    io.print "- N : \n"
    io.print "  - SAY : #{title} start.\n"
    for test_num in 1..1000 do
      addr      = rand(0x10000)
      data_size = rand(@axi4_data_size+1)
      data_len  = rand(@max_xfer_size)+1
      data_pos  = addr % (2**@offset_width)
      io.print "---\n"
      io.print "- MARCHAL : \n"
      io.print "  - SAY : " + title + "." + test_num.to_s + "\n"
      io.print @master.read( {
               :Address           => addr, 
               :Data              => @data[data_pos..data_pos+data_len-1], 
               :DataSize          => data_size,
               :DataXferPattern   => xfer_pattern,
               :Response          => "OKAY"
      })
    end
    io.print "---\n"
    io.print "- N : \n"
    io.print "  - SAY : #{title} done.\n"
    io.close
  end
end

gen = ScenarioGenerater.new("axi_slave_bfm test bench scenario", 32, 10)
gen.generate_init_ram_0("axi_slave_bfm_test.dat")
gen.generate_init_ram_2("axi_slave_bfm_test_2.dat")
gen.generate_scenario_2("axi_slave_bfm_test_2.snr")

