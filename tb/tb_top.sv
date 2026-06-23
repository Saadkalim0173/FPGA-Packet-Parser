//tb_top.sv
`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import packet_pkg::*;

module tb_top;

//clock generation 
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk; //100 mhz clock 

    //interface 
    parser_interface dut_if (.clk(clk));

    //dut 
    packet_parser u_dut(
        .clk    (clk),
        .rst_n  (dut_if.rst_n),
        .byte_valid (dut_if.byte_valid),
        .byte_in (dut_if.byte_in),
        .byte_ready (dut_if.byte_ready),
        .pkt_valid (dut_if.pkt_valid),
        .pkt_ready  (dut_if.pkt_ready),
        .pkt_type_out (dut_if.pkt_type_out),
        .payload_len_out (dut_if.payload_len_out),
        .src_id_out  (dut_if.src_id_out),
        .dst_id_out  (dut_if.dst_id_out),
        .seq_num_out  (dut_if.seq_num_out),
        .crc_ok     (dut_if.crc_ok),
        .parse_error    (dut_if.parse_error)
    );

    //reset sequence
    initial begin
        dut_if.rst_n = 0;
        dut_if.byte_valid = 0;
        dut_if.byte_in = 0;
        dut_if.pkt_ready = 1;
        repeat(5) @(posedge clk);
        dut_if.rst_n = 1;
    end

     // UVM config_db setup
  initial begin
    uvm_config_db #(virtual parser_interface.driver_mp)::set(
      null, "uvm_test_top.env.agent.driver", "vif", dut_if.driver_mp);
    uvm_config_db #(virtual parser_interface.monitor_mp)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", dut_if.monitor_mp);

    // Running the test specialized on terminal command
    run_test();
  end

  //timeout watchdog implemented
  initial begin
    #10_000_000;
    `uvm_fatal("TB_TOP", "Simulation TIMEOUT")
  end

  //waveform 
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_top);
  end

endmodule