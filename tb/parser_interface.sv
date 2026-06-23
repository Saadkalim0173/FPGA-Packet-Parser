`timescale 1ns/1ps
//parser_interface.sv 
import packet_pkg::*;

interface parser_interface (input logic clk);
logic   rst_n;
logic   byte_valid;
logic [7:0]     byte_in;
logic   byte_ready;
logic   pkt_valid;
logic   pkt_ready;
logic [7:0]     pkt_type_out;
logic [15:0]    payload_len_out;
logic [31:0]    src_id_out;
logic [31:0]    dst_id_out;
logic [15:0]    seq_num_out;
logic       crc_ok;
logic       parse_error;

//driver clocking block 
clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output rst_n, byte_valid, byte_in, pkt_ready;
    input byte_ready, pkt_valid, pkt_type_out, payload_len_out,
                      src_id_out, dst_id_out, seq_num_out, crc_ok, parse_error;
    endclocking

//monitor clocking block 
clocking monitor_cb @(posedge clk);
    default input #1;
    input rst_n, byte_valid, byte_in, byte_ready, pkt_valid, pkt_ready,
    pkt_type_out, payload_len_out, src_id_out, dst_id_out,
    seq_num_out, crc_ok, parse_error;
endclocking 

    modport driver_mp (clocking driver_cb, input clk);
    modport monitor_mp (clocking monitor_cb, input clk);

endinterface
