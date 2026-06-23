//pkt_coverage.sv
`ifndef PKT_COVERAGE_SV
`define PKT_COVERAGE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import packet_pkg::*;

class pkt_coverage extends uvm_subscriber #(pkt_seq_item);
    `uvm_component_utils(pkt_coverage)

    pkt_seq_item item;

    covergroup pkt_cg;
    //packet type coverage 
    cp_pkt_type: coverpoint item.pkt_type {
        bins data_pkt = {8'h01};
        bins ctrl_pkt = {8'h02};
        bins ack_pkt = {8'h03};
    }

    //payload lenght bins 
    cp_payload_len: coverpoint item.payload_len {
        bins min_len = {[1:10]};
        bins small_len = {[11:100]};
        bins medium_len = {[101:500]};
        bins large_len = {[501:1007]};
        bins max_len = {1008};
    }

    //typical error scenarios: 
    cp_crc_error: coverpoint item.inject_crc_error {
        bins no_error = {0};
        bins crc_error = {1};
    }
    //cross of packet type x (error)
    cx_type_error: cross cp_pkt_type, cp_crc_error;

    //cross of packet type x payload size 
    cx_type_len: cross cp_pkt_type, cp_payload_len;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        pkt_cg = new();
    endfunction 

    function void write(pkt_seq_item t);
        item = t;
        pkt_cg.sample();
    endfunction 

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf(
            "Functional Coverage: %.2f%%", pkt_cg.get_coverage()), UVM_NONE)
    endfunction 
        
endclass

`endif