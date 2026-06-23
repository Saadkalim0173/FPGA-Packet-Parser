//pkt_sequences.sv
`ifndef PKT_SEQUENCES_SV
`define PKT_SEQUENCES_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

//base sequence:
class pkt_base_seq extends uvm_sequence #(pkt_seq_item);
    `uvm_object_utils(pkt_base_seq)
    function new(string name = "pkt_base_seq");
        super.new(name);
    endfunction 
endclass

//normal random packets:
class pkt_normal_seq extends pkt_base_seq;
    `uvm_object_utils(pkt_normal_seq)
    int unsigned num_pkts = 50;

    function new(string name = "pkt_normal_seq");
        super.new(name);
    endfunction 

task body();
        pkt_seq_item item;
        repeat(num_pkts) begin
            item = pkt_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                inject_crc_error == 0;
                inject_bad_sof == 0;
                inject_bad_len == 0;
            }) `uvm_fatal("RAND", "Randomization FAILED")
            finish_item(item);
        end 
    endtask
endclass 

//crc error injection 
class pkt_crc_error_seq extends pkt_base_seq;
    `uvm_object_utils(pkt_crc_error_seq)
    int unsigned num_pkts = 20;

    function new(string name = "pkt_crc_error_seq");
        super.new(name);
    endfunction 

    task body();
        pkt_seq_item item;
        repeat(num_pkts) begin 
            item = pkt_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                inject_crc_error == 1;
                inject_bad_sof == 0;
                inject_bad_len == 0;
            }) `uvm_fatal("RAND", "Randomization failed")
            finish_item(item);
        end 
    endtask
endclass

//bad sof injection:
class pkt_bad_sof_seq extends pkt_base_seq;
    `uvm_object_utils(pkt_bad_sof_seq)
    int unsigned num_pkts = 10;
    
    function new(string name = "pkt_bad_sof_seq");
        super.new(name);
    endfunction 

    task body();
        pkt_seq_item item;
        repeat(num_pkts) begin 
            item = pkt_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                inject_crc_error == 0;
                inject_bad_sof == 1;
                inject_bad_len == 0;
            }) `uvm_fatal("RAND", "Randomization failed")
            finish_item(item);
        end 
    endtask
endclass

//bad len injection:
class pkt_bad_len_seq extends pkt_base_seq; 
    `uvm_object_utils(pkt_bad_len_seq)
    int unsigned num_pkts = 15;

    function new(string name = "pkt_bad_len_seq");
        super.new(name);
    endfunction 

    task body();
        pkt_seq_item item;
        repeat(num_pkts) begin 
            item = pkt_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                inject_crc_error == 0;
                inject_bad_sof == 0;
                inject_bad_len == 1;
            }) `uvm_fatal("RAND", "Randomization failed")
            finish_item(item);
        end 
    endtask
endclass 

//boundary condition (max and min payload)
class pkt_boundary_seq extends pkt_base_seq;
    `uvm_object_utils(pkt_boundary_seq)

    function new(string name = "pkt_boundary_seq");
        super.new(name);
    endfunction 

    task body();
        pkt_seq_item item;

        //minimum payload of 1 byte 
        item = pkt_seq_item::type_id::create("item_min");
        start_item(item);
        if (!item.randomize() with {
            payload_len == 16'd1;
            inject_crc_error == 0;
            inject_bad_sof == 0;
            inject_bad_len == 0;
        }) `uvm_fatal("RAND", "Randomization FAILED")
        finish_item(item);
        
        //max payload of 1008 bytes:
        item = pkt_seq_item::type_id::create("item_max");
        start_item(item);
        if (!item.randomize() with {
            payload_len == 16'd1008;
            inject_crc_error == 0;
            inject_bad_sof == 0;
            inject_bad_len == 0;
        }) `uvm_fatal("RAND", "Randomization failed")
        finish_item(item);
    endtask
endclass

//full mixed case text sequence 
class pkt_mixed_seq extends pkt_base_seq;
    `uvm_object_utils(pkt_mixed_seq)

    function new(string name = "pkt_mixed_seq");
        super.new(name);
    endfunction 

    task body();
        pkt_normal_seq  normal_seq;
        pkt_crc_error_seq   crc_seq;
        pkt_bad_sof_seq     sof_seq;
        pkt_bad_len_seq     len_seq;
        pkt_boundary_seq    boundary_seq;

        normal_seq = pkt_normal_seq::type_id::create("normal_seq");
        crc_seq = pkt_crc_error_seq::type_id::create("crc_seq");
        sof_seq = pkt_bad_sof_seq::type_id::create("sof_seq");
        len_seq = pkt_bad_len_seq::type_id::create("len_seq");
        boundary_seq = pkt_boundary_seq::type_id::create("boundary_seq");

        normal_seq.start(m_sequencer);
        crc_seq.start(m_sequencer);
        sof_seq.start(m_sequencer);
        len_seq.start(m_sequencer);
        boundary_seq.start(m_sequencer);
    endtask
endclass 

`endif