// packet_parser_sva.sv
import packet_pkg::*;

module packet_parser_sva (
    input logic     clk,
    input logic     rst_n,
    input logic     byte_valid,
    input logic [7:0]   byte_in,
    input logic      byte_ready,
    input logic      pkt_valid,
    input logic      pkt_ready,
    input logic [7:0]   pkt_type_out,
    input logic [15:0]  payload_len_out,
    input logic [31:0]  src_id_out,
    input logic [31:0]  dst_id_out,
    input logic        crc_ok,
    input logic        parse_error
);

//valid handshake so if pkt_valid is high and pkt_ready is low then pkt_valid must stay 
// high the next cycle so no dropping valid actual data
property p_pkt_valid_stable;
    @(posedge clk) disable iff (!rst_n)
    (pkt_valid && !pkt_ready) | => pkt_valid;
endproperty
A_PKT_VALID_STABLE: assert property (p_pkt_valid_stable)
    else $error("ASSERTION FAIL: pkt_valid dropped without pkt_ready");

//byte_valid or byte_ready ready handshake: byte_reay must not be x or z
A_BYTE_READY_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    !$isunknown(byte_ready)
) else $error("ASSERTION FAIL: byte_ready is X or Z");

//pkt_valid must not be x/z: 
A_PKT_VALID_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    !isunknown(pkt_valid)
) else $error("ASSERTION FAIL: pkt_valid is X or Z");

//when pkt_valid, crc_ok and parse_error MUST be complementary meaning they are not mutually exclusive in order to stop a status contradiction
A_CRC_PARSE_MUTEX: assert property (
    @(posedge clk) disable iff (!rst_n)
    pkt_valid | -> !(crc_ok && parse_error)
) else $error("ASSERTION FAIL: crc_ok and parse_error both asserted");

//payload_len MUST BE in the range of [1:1008] when both pkt_valid and crc_ok,
A_PAYLOAD_LEN_RANGE: assert property (
    @(posedge clk) disable iff (!rst_n)
    (pkt_valid && crc_ok) |->
        (payload_len_out >= 16'd1 && payload_len_out <= 16'd1008)
) else $error("ASSERTION FAIL: payload_len out of valid range if pkt_valid and crc_ok");

//pkt_type must have valid enum value when pkt_valid and crc_ok
A_PKT_TYPE_VALID: assert property (
    @(posedge clk) disable iff (!rst_n)
    (pkt_valid && crc_ok) |->
        (pkt_type_out == 8'h01 || pkt_type_out == 8'h02 || pkt_type_out == 8'h03)
) else $error("ASSERTION FAIL: invalid pkt_type on output");

//after clock reset pkt_valid must be low for atleast the next one cycle
A_RST_PKT_VALID_LOW: assert property (
    @(posedge clk)
    $rose(rst_n) | => !pkt_valid
) else $error("ASSERTION FAIL: pkt_valid high immediately after reset release of clock");

//after reset of clock byte_ready must eventually become high
A_RST_BYTE_READY_EVENTUALLY: assert property (
    @(posedge clk)
    $rose(rst_n) | ##[1:5] byte_ready
) else $error ("ASSERTION FAIL: byte_ready never went high after clock reset");

//byte_in must not be x or z when byte_valid is high 
A_BYTE_IN_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    byte_valid |-> !$isunknown(byte_in)
) else $error ("ASSERTION FAIL: byte_in is x/z while byte_valid is high");

//pkt_type_out must not be x/z when pkt_valid is high
A_PKT_TYPE_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid |-> !$isunknown(pkt_type_out)
) else $error ("ASSERTION FAIL: pkt_type_out is in x/z while pkt_valid is high");

//src_id must not be x/z when pkt_valid is high 
A_SRC_ID_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid | -> !$isunknown(src_id_out)
) else $error ("ASSERTION FAIL: src_id_out is x/z while pkt_valid is high");

//dst_id must not be x/z when pkt_valid is high 
A_DST_ID_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid | -> !$isunknown(dst_id_out)
) else $error ("ASSERTION FAIL: dst_id_out is x/z while pkt_valid is high");

//seq_num must not be x/z when pkt_valid is high
A_SEQ_NUM_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid | -> !$isunknown(seq_num_out)
) else $error ("ASSERTION FAIL: seq_num_out is x/z while pkt_valid is high");

//crc_ok must not be x/z when pkt_valid is high
A_CRC_OK_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid | -> !$isunknown(crc_ok)
) else $error ("ASSERTION FAIL: crc_ok is x/z while pkt_valid is high");

//parse_error must not be x/z when pkt_valid is high 
A_PARSE_ERROR_KNOWN: assert property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid | -> !$isunknown(crc_ok)
) else $error ("ASSERTION FAIL: parse_error is x/z while pkt_valid is high")

//throughput check so pkt_valid should not stay asserted more than 1 cycle without ready
//stall limit so valid held alert after 10
A_VALID_STALL_LIMIT: assert property (
    (@posedge clk) disable iff (!rst_n)
    pkt_valid |-> [0:10] pkt_ready
) else $error ("WARN!: pkt_valid stalled for >10 cycles without pkt_ready");

//when parse_error is set crc_ok MUST BE LOW
A_ERROR_CRC_LOW: assert property(
    (@posedge clk) disable iff (!rst_n)
    parse_error |-> !crc_ok
) else $error("ASSERTION FAIL: parse_error set BUT crc_ok must be set as well to low");

//payload_len must not be x/z when pkt_valid 
A_PAYLOAD_LEN_ERROR_KNOWN: assert property(
    (@posedge clk) disable iff (!rst_n)
    pkt_valid |-> !$isunknown(payload_len_out)
) else $error("ASSERTION FAIL: payload_len_out is x/z when pkt_valid is high");

//byte_valid and byte_ready must not be both X simultaneously
A_HANDSHAKE_NO_X: assert property (
    @(posedge clk) disable iff (!rst_n)
    !($isunknown(byte_valid) && !isunknown(byte_ready))
) else $error ("ASSERTION FAIL: both byte_valid and byte_ready are X");

// pkt_valid must be a single cycle pulse unless held by back pressue 
// or in simpler langauge lol if pkt_ready, pkt_valid should de-assert next cycle
property p_valid_deasserts_after_ready;
@(posedge clk) disable iff (!rst_n)
(pkt_valid && pkt_ready) || => !pkt_valid;
endproperty 
A_VALID_DEASSERTSL assert property (p_valid_deasserts_after_ready)
else $error ("ASSERTION FAIL: pkt_valid stayed high EVEN AFTER pkt_ready accepted");

//crc failure coverage: parse_error toggles eventually 
C_PARSE_ERROR_SEEN: cover property(
    @(posedge clk) disable iff (!rst_n)
    parse_error
);

//successfull packet coverage
C_GOOD_PKT_SEEN: cover property(
    @(posedge clk) disable iff (!rst_n)
    pkt_valid && crc_ok
);

//back-pressure stall coverage 
C_BACKPRESSURE_SEEN: cover property (
    @(posedge clk) disable iff (!rst_n)
    pkt_valid && !pkt_ready
);

//data packet type seen 
C_DATA_PKT: cover property (
    @(posedge clk) disable iff (!rst_n)
    pkt_valid && crc_ok && (pkt_type_out == 8'h01)
);

//ctrl packet type seen
C_CTRL_PKT: cover propety (
    (posedge clk) disable iff (!rst_n)
    pkt_valid && crc_ok && (pkt_type_out == 8'h02)
); 

//ack packet type seen 
C_ACK_PKT: cover propety (
    (posedge clk) disable iff (!rst_n)
    pkt_valid && crc_ok && (pkt_type_out == 8'h03)
);

//1 byte = minimum size payload 
C_MIN_PAYLOAD: cover property (
    @(posedge clk) disable iff (!rst_n)
    pkt_valid && crc_ok && (payload_len_out == 16'd48) // 64b total which is also a 16b header
);

endmodule 

//bind to dut (design under test for uvm) without touching rtl 
bind packet_parser packet_parser_sva u_sva (.*);
