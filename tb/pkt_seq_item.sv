//pkt_seq_item.sv

`ifndef PKT_SEQ_ITEM_SV
`define PKT_SEQ_ITEM_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import packet_pkg::*;

class pkt_seq_item extends uvm_sequence_item;

    //randomazition of fields 
    rand logic [7:0] pkt_type;
    rand logic [15:0] payload_len;
    rand logic [31:0] src_id;
    rand logic [31:0] dst_id;
    rand logic [15:0] seq_num;

    //flags if errors occurs and injection of error
    rand bit inject_crc_error;
    rand bit inject_bad_sof;
    rand bit inject_bad_len;    //foreces len to be 0 OR be > 1008

    `uvm_object_utils_begin(pkt_seq_item)
         `uvm_field_int(pkt_type, UVM_ALL_ON)
         `uvm_field_int(payload_len, UVM_ALL_ON)
         `uvm_field_int(src_id, UVM_ALL_ON)
         `uvm_field_int(dst_id, UVM_ALL_ON)
         `uvm_field_int(seq_num, UVM_ALL_ON)
         `uvm_field_int(inject_crc_error, UVM_ALL_ON)
         `uvm_field_int(inject_bad_sof, UVM_ALL_ON)
         `uvm_field_int(inject_bad_len, UVM_ALL_ON)
    `uvm_object_utils_end

    //our constraints 
    constraint c_pkt_type {
        pkt_type inside {8'h01, 8'h02, 8'h03};
    }

    constraint c_payload_len {
        if(!inject_bad_len)
            payload_len inside {[16'd1 : 16'd1008]};
        else
            payload_len inside {16'd0, [16'd1009: 16'd1023]};
    }

    constraint c_error_weight {
        inject_crc_error dist {0 := 80, 1:= 20};
        inject_bad_sof dist {0:= 90, 1:= 10};
        inject_bad_len dist {0:= 85, 1:= 15};
    }

    //a maximum of one error type at a type to provide for cleaner more efficient debugging
    constraint c_one_error {
        (inject_crc_error + inject_bad_len + inject_bad_sof) <= 1;
    }

    function new(string name = "pkt_seq_item");
        super.new(name);
    endfunction 

    //build the raw byte array for packet
    function automatic void build_byte_stream(output logic [7:0] stream [$]);
        logic [7:0] sof_byte;
        logic [15:0] crc;
        logic [15:0] crc_tmp;
        logic [7:0] hdr[16];
        int     i;

    //sof 
    sof_byte = inject_bad_sof ? 8'hFF: SOF_BYTE;

    //assemble all our header bytes
    hdr[0] = sof_byte;
    hdr[1] = pkt_type;
    hdr[2] = payload_len[15:8];
    hdr[3] = payload_len[7:0];
    hdr[4] = src_id[31:24];
    hdr[5] = src_id[23:16];
    hdr[6] = src_id[15:8];
    hdr[7] = src_id[7:0];
    hdr[8] = dst_id[31:24];
    hdr[9] = dst_id[23:16];
    hdr[10] = dst_id[15:8];
    hdr[11] = dst_id[7:0];
    hdr[12] = seq_num[15:8];
    hdr[13] = seq_num[7:0];

//compute crc value again over bytes 0-13
    crc = 16'hFFFF;
    for (i = 0; i < 14; i++) begin
        //inline crc 16 ccittt
        for (int b = 7; b >= 0; b--) begin
            if ((hdr[i][b] ^ crc[15]) == 1'b1)
                crc = {crc[14:0], 1'b0} ^ CRC16_POLY;
            else 
                crc = {crc[14:0], 1'b0};
        end
    end 

    if (inject_crc_error) crc = crc ^ 16'hDEAD; // corrupt the crc

    hdr[14] = crc[15:8];
    hdr[15] = crc[7:0];

    stream = {};
    for (i = 0; i < 16; i++)
        stream.push_back(hdr[i]);

        //push payload bytes or random data 
        for (i = 0; i < payload_len; i++)
            stream.push_back($urandom_range(0,255));
        
    endfunction 
    
endclass 

`endif