// packet_pkg.sv
package packet_pkg;

//packet can handle packages ranging from 64b to 1kb, which is 64 to 1024 byes
// header is fixed at 16 bytes
// [0] = start of frame or 0xAB
// [1] = packet type (0x01 = Data Packet, 0x02 = ctrl packet, 0x03 = ack packet)
// [2:3] = payload lenght (2 bytes, big-endian)
// [4:7] = source id (4 bytes)
// [8:11] = destination id (4 bytes)
// [12:13] = sequence number (2 bytes)
// [14:15] = crc16 (2 last bytes, covers bytes 0-13)

parameter int HEADER_BYTES = 16;
parameter int MAX_PKT_BYTES = 1024;
parameter int MIN_PKT_BYTES = 64; 
parameter int DATA_WIDTH = 8; //which is byte-serial input

typedef enum logic [1:0] {
	PKT_DATA = 2'b01,
	PKT_CTRL = 2'b10,
	PKT_ACK = 2'b11
} pkt_type_e; 

typedef struct packed {
logic [7:0] sof;
logic [7:0] pkt_type;
logic [15:0] payload_len;
logic [31:0] src_id;
logic [31:0] dst_id;
logic [15:0] seq_num;
logic [15:0] crc16;
} pkt_header_t; //128 bits is equzl to 16 bytes 

// crc16-ccitt polynomial: x^16 + x^12 + x^5 + 1
parameter logic [15:0] CRC16_POLY = 16'h1021;
parameter logic [7:0] SOF_BYTE = 8'hAB;

endpackage 