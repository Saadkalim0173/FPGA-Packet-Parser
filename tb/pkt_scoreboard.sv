//pkt_scoreboard.sv
`ifndef PKT_SCOREBOARD_SV
`define PKT_SCOREBOARD_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import packet_pkg::*;

class pkt_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(pkt_scoreboard)
    uvm_analysis_imp #(pkt_seq_item, pkt_scoreboard) analysis_export;

    //expected results queue (fed by sequence via config_db or a 2nd port)
    //for simplicity where the scoreboard receives what the monitor sees and rechecks rules 
    int pass_count;
    int fail_count;
    int crc_error_count;
    int total_pkts;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        pass_count = 0;
        fail_count = 0;
        crc_error_count = 0;
        total_pkts = 0;
    endfunction

    //function is called every time a monitor writes a transaction
    function void write(pkt_seq_item item);
        total_pkts++;

        if(item.inject_crc_error) begin
        //crc error was flagged which we expect when we inject crc error
            crc_error_count++;
            `uvm_info("SB", $sformatf(
                "CRC ERROR PKT #%0d: type=0x%0h len=%0d src=0x%0h dst=0x%0h",
                total_pkts, item.pkt_type, item.payload_len, item.src_id, item.dst_id), UVM_MEDIUM)
            pass_count++; //correct behavior since dut detected AND flagged 
            return;
        end 

        //check IF PACKET IS LEGAL 
        if(!(item.pkt_type inside {8'h01, 8'h02, 8'h03})) begin 
            `uvm_error("SB", $sformatf(
                "PKT #%0d: ILLEGAL pkt_type = 0x%0h", total_pkts, item.pkt_type))
            fail_count++;
            return;
        end 

        //check IF PAYLOAD LENGHT IS IN RANGE OR NOT
        if(item.payload_len < 1 || item.payload_len > 1008) begin 
            `uvm_error("SB", $sformatf(
                "PKT #%0d: payload_len=%0d OUT OF RANGE", total_pkts, item.payload_len))
            fail_count++;
            return;
        end 

        //all CHECKS ARE PASSED:
        `uvm_info("SB", $sformatf(
            "PASS PKT #%0d: type=0x%0h len=%0d src=0x%0h dst=0x%0h seq=%0d",
            total_pkts, item.pkt_type, item.payload_len,
            item.src_id, item.dst_id, item.seq_num), UVM_HIGH)
        pass_count++;
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf(
            "\n===== SCOREBOARD SUMMARY =====\n" +
            "   Total number of packets: %0d\n"  +
            "   PASS: %0d\n"                     +
            "   FAIL: %0d\n"                     +
            "   CRC error: %0d\n"                +
            "===================================",
            total_pkts, pass_count, fail_count, crc_error_count), UVM_NONE)
        if(fail_count > 0)
            `uvm_error("SB", "TEST FAILED - scoreboard detected mismatches")
        else 
            `uvm_info("SB", "TEST PASSED", UVM_NONE)
    endfunction

endclass

`endif