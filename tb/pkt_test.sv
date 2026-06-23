//pkt_test.sv
`ifndef PKT_TEST_SV
`define PKT_TEST_SV 

import uvm_pkg::*;
`include "uvm_macros.svh"
//base tests:
class pkt_base_test extends uvm_test;
    `uvm_component_utils(pkt_base_test)

    pkt_env env;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = pkt_env::type_id::create("env", this);
    endfunction 

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        reset_dut();
        phase.drop_objection(this);
    endtask 

    task reset_dut();
    endtask
endclass 

//sanity testing with 10 normal packets 
class pkt_sanity_test extends pkt_base_test;
    `uvm_component_utils(pkt_sanity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    task run_phase(uvm_phase phase);
        pkt_normal_seq seq;
        phase.raise_objection(this);
        seq = pkt_normal_seq::type_id::create("seq");
        seq.num_pkts = 10;
        seq.start(env.agent.sequencer);
        #200;
        phase.drop_objection(this);
    endtask
endclass 

//full coverage testing
class pkt_full_test extends pkt_base_test;
    `uvm_component_utils(pkt_full_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    task run_phase(uvm_phase phase);
        pkt_mixed_seq seq;
        phase.raise_objection(this);
        seq = pkt_mixed_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #500;
        phase.drop_objection(this);
    endtask 
endclass 

//crc only stress testing 
class pkt_crc_test extends pkt_base_test;
    `uvm_component_utils(pkt_crc_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    task run_phase(uvm_phase phase);
        pkt_crc_error_seq seq;
        phase.raise_objection(this);
        seq = pkt_crc_error_seq::type_id::create("seq");
        seq.num_pkts = 50;
        seq.start(env.agent.sequencer);
        #500;
        phase.drop_objection(this);
    endtask 
endclass

`endif