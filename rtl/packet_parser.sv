//packet_parser.sv 
import packet_pkg::*;

module packet_parser (
    input logic     clk,
    input logic     rst_n,
    //our input byte stream
    input logic     byte_valid,
    input logic[7:0]    byte_in,
    output logic    byte_ready,
    //our parsed output metadata
    output logic    pkt_valid,
    input logic     pkt_ready,
    output logic [7:0] pkt_type_out,
    output logic [15:0] payload_len_out,
    output logic [31:0] src_id_out,
    output logic [31:0] dst_id_out,
    output logic [15:0] seq_num_out,
    output logic    crc_ok,
    output logic    parse_error
); 

// our first stage is byte detection and sof detection 

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_HDR,
        ST_PAYLOAD,
        ST_DONE,
        ST_ERROR
    } fsm_t; 

    fsm_t   state;
    logic [15:0] plen_tmp;
    logic [10:0]    byte_cnt; //can handle upto 1024
    logic [127:0]   hdr_shift; //our 16 byte shift register 
    logic [15:0]    crc_accum; 
    logic [15:0]    payload_remaining;

    //our crc module wiring 
    logic [15:0] crc_next;
    crc16 u_crc16 (
        .crc_in (crc_accum),
        .data_in (byte_in),
        .crc_out (crc_next)
    );

// out next step is to incorporate header capture and crc accum

//pipeline stage 1 outputs 
logic[127:0] s1_header;
logic   s1_valid;

//pipeline stage2 outputs 
logic [15:0]    s2_crc_computed;
logic [127:0]   s2_header;
logic   s2_valid; 

//pipeline stage 3 outputs
logic [15:0] s3_crc_expected;
logic [15:0] s3_crc_computed; 
logic [127:0] s3_header;
logic         s3_crc_ok;
logic         s3_valid;

//pipeline stage 4 outputs
logic          s4_valid;
logic          s4_crc_ok;
logic          s4_parse_error;
logic   [7:0] s4_pkt_type;
logic   [15:0] s4_payload_len;
logic   [31:0] s4_src_id;
logic   [31:0] s4_dst_id;
logic   [15:0] s4_seq_num;

//our finite state machine (sequential)

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    state       <= ST_IDLE;
    byte_cnt    <= '0;
    hdr_shift   <= '0;
    crc_accum   <= 16'hFFFF;
    payload_remaining   <= '0;
    s1_valid    <= '0;
    s1_header   <= '0;
end else begin 
    s1_valid    <= 0; //default state

    case(state)
    //idle state wait for sof
    ST_IDLE: begin
    crc_accum <= 16'hFFFF;
    byte_cnt  <= '0;
    if (byte_valid && byte_ready) begin
        if (byte_in == SOF_BYTE) begin
            hdr_shift <= {hdr_shift[119:0], byte_in};
            crc_accum <= crc_next;
            byte_cnt <= 11'd1;
            state    <= ST_HDR;
        end
    end
end 

//hdr stage where we collect 16 header bytes
ST_HDR: begin 
    if (byte_valid && byte_ready) begin
        hdr_shift <= {hdr_shift[119:0], byte_in};
        byte_cnt  <= byte_cnt + 1;

        //crc over bytes 0-13 only (not bytes 14 and 15 since they are the crc)
        if (byte_cnt < 11'd14)
            crc_accum <= crc_next;

        if (byte_cnt == 11'd15) begin
        //all the 16 header bits received so we can push to stage 1
        s1_header <= {hdr_shift[119:0], byte_in};
        s1_valid <= 1;

        //we need to check the lenght of the payload before moving on
        //our payload_len is stored in hdr_shift[95:80] at this stage
        //hdr_shift after 16 bytes is as follows: [127:120] = sof, [119:112] = type,
        //[111:96] = payload_len after the shift now we can begin
    plen_tmp <= hdr_shift[111:96]; //pretty sure we can still s1_header but still better safe than sorry
        if (hdr_shift[111:96] > 16'd1008 || hdr_shift[111:96] == 16'd0) begin
        state <= ST_ERROR;
        end else begin
        payload_remaining <= hdr_shift[111:96];
        state    <= ST_PAYLOAD;
            byte_cnt <= '0;
end
        end
    end
end

//payload: count the payload bytes
ST_PAYLOAD: begin
    if(byte_valid && byte_ready) begin
        if(payload_remaining == 16'd1) begin
            state <= ST_DONE;
        end else begin 
            payload_remaining <= payload_remaining -1;
        end
    end
end

//done: pulse for only 1 cycle tho
    ST_DONE: begin
        state   <= ST_IDLE;
        byte_cnt <= '0;
    end

//error if it doesnt work
    ST_ERROR: begin
      state   <= ST_IDLE;
     byte_cnt <= '0;
    end

    default: state <= ST_IDLE;
    endcase
end
end


//stage 2 where we latch our header and hold crc values

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s2_valid    <=0;
        s2_crc_computed <='0;
        s2_header   <= '0;
    end else begin
        s2_valid    <= s1_valid; 
        s2_header   <= s1_header;
        s2_crc_computed <= crc_accum; //latched at the very end of the header
    end
end

//stage 3 which is the crc comparison to ensure packet is non corrupted

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        s3_valid    <= 0;
        s3_crc_ok   <= 0;
        s3_header   <= '0;
        s3_crc_computed <= '0;
        s3_crc_expected <= '0;
    end else begin 
        s3_valid    <= s2_valid;
        s3_header   <= s2_header;
        s3_crc_computed <= s2_crc_computed;
        //crc field is in bits [15:0] of the 128 bit header
        s3_crc_expected <= s2_header[15:0];
        s3_crc_ok   <= (s2_crc_computed == s2_header[15:0]);
    end
end

//our metadata extraction phase and final output 

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s4_valid    <= 0;
        s4_crc_ok   <= 0;
        s4_parse_error   <= 0;
        s4_pkt_type     <= 0;
        s4_payload_len  <= 0;
        s4_src_id   <= 0;
        s4_dst_id   <= 0;
        s4_seq_num  <= 0;
    end else if (!pkt_valid || pkt_ready) begin
    //only advance through the pipelined stage 4 if downstream is ready or we have nothing valid
        s4_valid    <= s3_valid;
        s4_crc_ok   <= s3_crc_ok;
        s4_parse_error <= s3_valid && !s3_crc_ok;
    
    // extraction from the 128 bit header:
    //[127:120] = SOF
    //[119:112] = pkt_type
    //[111:96] = payload_len
    //[95:64] = src_id
    //[63:32] = dst_id
    //[31:16] = seq_num
    //[15:0] = crc16 

    s4_pkt_type <= s3_header[119:112];
    s4_payload_len <= s3_header[111:96];
    s4_src_id <= s3_header[95:64];
    s4_dst_id <= s3_header[63:32];
    s4_seq_num <= s3_header[31:16];
    
    end
end

//final output assignments

assign pkt_valid = s4_valid;
assign crc_ok = s4_crc_ok;
assign parse_error = s4_parse_error;
assign pkt_type_out = s4_pkt_type;
assign payload_len_out = s4_payload_len;
assign src_id_out = s4_src_id;
assign dst_id_out = s4_dst_id;
assign seq_num_out = s4_seq_num;

//final back pressue where it accepts bytes only when not in done or error

    assign byte_ready = (state != ST_DONE) && (state != ST_ERROR);

endmodule