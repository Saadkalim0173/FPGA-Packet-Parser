//pkt_monitor.sv
`ifndef PKT_MONITOR_SV
`define PKT_MONITOR_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import packet_pkg::*;

class pkt_monitor extends uvm_monitor;
    `uvm_component_utils(pkt_monitor)

    virtual parser_interface.monitor_mp vif;
    uvm_analysis_port #(pkt_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual parser_interface.monitor_mp)::get(
            this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "Monitor: Virtual interface NOT FOUND!")
    endfunction 

    task run_phase(uvm_phase phase);
        pkt_seq_item obs;

        @(posedge vif.clk iff vif.monitor_cb.rst_n == 1'b1);

        forever begin 
            //wait for a valid output transaction only 
            @(posedge vif.clk);
            if (vif.monitor_cb.pkt_valid && vif.monitor_cb.pkt_ready) begin 
                obs = pkt_seq_item::type_id::create("obs");
                obs.pkt_type = vif.monitor_cb.pkt_type_out;
                obs.payload_len = vif.monitor_cb.payload_len_out;
                obs.src_id = vif.monitor_cb.src_id_out;
                obs.dst_id = vif.monitor_cb.dst_id_out;
                obs.seq_num = vif.monitor_cb.seq_num_out;
                //capture error flags into spare fields
                obs.inject_crc_error = vif.monitor_cb.crc_ok ? 0:1;
                obs.inject_bad_sof = 0;
                obs.inject_bad_len = 0;
                ap.write(obs);
            end
        end
    endtask

endclass

`endif