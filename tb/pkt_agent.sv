//pkt_agent.sv
`ifndef PKT_AGENT_SV
`define PKT_AGENT_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class pkt_agent extends uvm_agent;
    `uvm_component_utils(pkt_agent)

    pkt_driver  driver;
    pkt_monitor monitor;
    uvm_sequencer   #(pkt_seq_item) sequencer;

    uvm_analysis_port #(pkt_seq_item) ap; //forwarded from the monitor 
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap      = new("ap", this);
        monitor = pkt_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin 
            driver = pkt_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(pkt_seq_item)::type_id::create("sequencer", this);
        end 
    endfunction 

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction 

endclass
`endif