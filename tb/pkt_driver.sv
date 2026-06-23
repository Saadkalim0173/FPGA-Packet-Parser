//pkt_driver.sv 
`ifndef PKT_DRIVER_SV
`define PKT_DRIVER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import packet_pkg::*;

class pkt_driver extends uvm_driver #(pkt_seq_item);
    `uvm_component_utils(pkt_driver)

    virtual parser_interface.driver_mp vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual parser_interface.driver_mp)::get(
            this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "Driver: virtual interface not found")
    endfunction 

    task run_phase(uvm_phase phase);
        pkt_seq_item item;
        logic [7:0] byte_stream[$];
    
        //default outputs
        vif.driver_cb.byte_valid <= 0;
        vif.driver_cb.byte_in   <= 0;
        vif.driver_cb.pkt_ready <= 1;

        //wait for it to reset
        @(posedge vif.clk iff vif.driver_cb.rst_n === 1'b1);
        repeat(3) @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(item);

            item.build_byte_stream(byte_stream);

            foreach (byte_stream[i]) begin
            //we have to wait for dut to get ready 
            @(posedge vif.clk);
            while (!vif.driver_cb.byte_ready) @(posedge vif.clk);

            vif.driver_cb.byte_valid <= 1;
            vif.driver_cb.byte_in <= byte_stream[i];
            @(posedge vif.clk);
            vif.driver_cb.byte_valid <= 0;
        end

        //a small gap between each packet
        repeat(2) @(posedge vif.clk);

        seq_item_port.item_done();
    end
endtask 

endclass

`endif