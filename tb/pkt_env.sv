//pkt_env.sv
`ifndef PKT_ENV_SV
`define PKT_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class pkt_env extends uvm_env;
    `uvm_component_utils(pkt_env)

    pkt_agent       agent;
    pkt_scoreboard  scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = pkt_agent::type_id::create("agent", this);
        scoreboard = pkt_scoreboard::type_id::create("scoreboard", this);
    endfunction 
    
    function void connect_phase(uvm_phase phase);
        agent.ap.connect(scoreboard.analysis_export);
    endfunction 

endclass

`endif