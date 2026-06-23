//crc16.sv
import packet_pkg::*;

module crc16 (
    input logic [15:0] crc_in,
    input logic [7:0] data_in,
    output logic [15:0] crc_out
);
    logic [15:0] crc;
    logic [7:0] d;
    logic [15:0] c;

    always_comb begin
        d = data_in;
        c = crc_in;
        crc = c;
        for (int i = 7; i >=0; i--) begin
            if ((d[i] ^ crc[15]) == 1'b1)
                crc = {crc[14:0], 1'b0} ^ CRC16_POLY;
            else
                crc = {crc[14:0], 1'b0};
            end
            crc_out = crc;
        end 
endmodule 
