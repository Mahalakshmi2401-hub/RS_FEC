`timescale 1ns/1ps
module rs_fec_config
(
    input  wire [2:0] speed_grade,
    output reg  [7:0] payload_bytes,
    output reg  [4:0] parity_bytes
);
always @(*) begin
    case(speed_grade)
        3'b000, 3'b001: begin
            payload_bytes = 8'd214;
            parity_bytes  = 5'd2;
        end
        3'b010, 3'b011, 3'b100: begin
            payload_bytes = 8'd214;
            parity_bytes  = 5'd26;
        end
        3'b101, 3'b110: begin
            payload_bytes = 8'd106;
            parity_bytes  = 5'd2;
        end
        default: begin
            payload_bytes = 8'd214;
            parity_bytes  = 5'd2;
        end
    endcase
end
endmodule
