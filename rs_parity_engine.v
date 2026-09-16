`timescale 1ns/1ps

module rs_parity_engine
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] current_data,
    input  wire       data_valid,
    input  wire [4:0] parity_bytes,
    input  wire       parity_clear,
    input  wire [4:0] parity_rd_idx,
    output reg  [7:0] parity_out
);

reg [7:0] p0_2;
reg [7:0] p1_2;
wire [7:0] fb2 = current_data ^ p1_2;
wire [7:0] mult2_g0;
wire [7:0] mult2_g1;

gf_mult u_g0 (.a(fb2),.b(8'h02),.product(mult2_g0));
gf_mult u_g1 (.a(fb2),.b(8'h03),.product(mult2_g1));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        p0_2 <= 8'h00;
        p1_2 <= 8'h00;
    end
    else if(parity_clear) begin
        p0_2 <= 8'h00;
        p1_2 <= 8'h00;
    end
    else if(data_valid && (parity_bytes == 5'd2)) begin
        p1_2 <= p0_2 ^ mult2_g1;
        p0_2 <= mult2_g0;
    end
end

reg [7:0] p [0:25];
wire [7:0] feedback26 = current_data ^ p[25];
wire [7:0] mult [0:25];

localparam [7:0] G0  = 8'h5E;
localparam [7:0] G1  = 8'h2B;
localparam [7:0] G2  = 8'h4D;
localparam [7:0] G3  = 8'h92;
localparam [7:0] G4  = 8'h90;
localparam [7:0] G5  = 8'h46;
localparam [7:0] G6  = 8'h44;
localparam [7:0] G7  = 8'h87;
localparam [7:0] G8  = 8'h2A;
localparam [7:0] G9  = 8'hE9;
localparam [7:0] G10 = 8'h75;
localparam [7:0] G11 = 8'hD1;
localparam [7:0] G12 = 8'h28;
localparam [7:0] G13 = 8'h91;
localparam [7:0] G14 = 8'h18;
localparam [7:0] G15 = 8'hCE;
localparam [7:0] G16 = 8'h38;
localparam [7:0] G17 = 8'h4D;
localparam [7:0] G18 = 8'h98;
localparam [7:0] G19 = 8'hC7;
localparam [7:0] G20 = 8'h62;
localparam [7:0] G21 = 8'h88;
localparam [7:0] G22 = 8'h04;
localparam [7:0] G23 = 8'hB7;
localparam [7:0] G24 = 8'h33;
localparam [7:0] G25 = 8'hF6;

gf_mult gm0  (.a(feedback26),.b(G0 ),.product(mult[0 ]));
gf_mult gm1  (.a(feedback26),.b(G1 ),.product(mult[1 ]));
gf_mult gm2  (.a(feedback26),.b(G2 ),.product(mult[2 ]));
gf_mult gm3  (.a(feedback26),.b(G3 ),.product(mult[3 ]));
gf_mult gm4  (.a(feedback26),.b(G4 ),.product(mult[4 ]));
gf_mult gm5  (.a(feedback26),.b(G5 ),.product(mult[5 ]));
gf_mult gm6  (.a(feedback26),.b(G6 ),.product(mult[6 ]));
gf_mult gm7  (.a(feedback26),.b(G7 ),.product(mult[7 ]));
gf_mult gm8  (.a(feedback26),.b(G8 ),.product(mult[8 ]));
gf_mult gm9  (.a(feedback26),.b(G9 ),.product(mult[9 ]));
gf_mult gm10 (.a(feedback26),.b(G10),.product(mult[10]));
gf_mult gm11 (.a(feedback26),.b(G11),.product(mult[11]));
gf_mult gm12 (.a(feedback26),.b(G12),.product(mult[12]));
gf_mult gm13 (.a(feedback26),.b(G13),.product(mult[13]));
gf_mult gm14 (.a(feedback26),.b(G14),.product(mult[14]));
gf_mult gm15 (.a(feedback26),.b(G15),.product(mult[15]));
gf_mult gm16 (.a(feedback26),.b(G16),.product(mult[16]));
gf_mult gm17 (.a(feedback26),.b(G17),.product(mult[17]));
gf_mult gm18 (.a(feedback26),.b(G18),.product(mult[18]));
gf_mult gm19 (.a(feedback26),.b(G19),.product(mult[19]));
gf_mult gm20 (.a(feedback26),.b(G20),.product(mult[20]));
gf_mult gm21 (.a(feedback26),.b(G21),.product(mult[21]));
gf_mult gm22 (.a(feedback26),.b(G22),.product(mult[22]));
gf_mult gm23 (.a(feedback26),.b(G23),.product(mult[23]));
gf_mult gm24 (.a(feedback26),.b(G24),.product(mult[24]));
gf_mult gm25 (.a(feedback26),.b(G25),.product(mult[25]));

integer k;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(k=0;k<26;k=k+1)
            p[k] <= 8'h00;
    end
    else if(parity_clear) begin
        for(k=0;k<26;k=k+1)
            p[k] <= 8'h00;
    end
    else if(data_valid && (parity_bytes == 5'd26)) begin
        p[25] <= p[24] ^ mult[25];
        p[24] <= p[23] ^ mult[24];
        p[23] <= p[22] ^ mult[23];
        p[22] <= p[21] ^ mult[22];
        p[21] <= p[20] ^ mult[21];
        p[20] <= p[19] ^ mult[20];
        p[19] <= p[18] ^ mult[19];
        p[18] <= p[17] ^ mult[18];
        p[17] <= p[16] ^ mult[17];
        p[16] <= p[15] ^ mult[16];
        p[15] <= p[14] ^ mult[15];
        p[14] <= p[13] ^ mult[14];
        p[13] <= p[12] ^ mult[13];
        p[12] <= p[11] ^ mult[12];
        p[11] <= p[10] ^ mult[11];
        p[10] <= p[9]  ^ mult[10];
        p[9]  <= p[8]  ^ mult[9];
        p[8]  <= p[7]  ^ mult[8];
        p[7]  <= p[6]  ^ mult[7];
        p[6]  <= p[5]  ^ mult[6];
        p[5]  <= p[4]  ^ mult[5];
        p[4]  <= p[3]  ^ mult[4];
        p[3]  <= p[2]  ^ mult[3];
        p[2]  <= p[1]  ^ mult[2];
        p[1]  <= p[0]  ^ mult[1];
        p[0]  <= mult[0];
    end
end

always @(*) begin
    if(parity_bytes == 5'd2) begin
        case(parity_rd_idx)
            5'd0: parity_out = p1_2;
            5'd1: parity_out = p0_2;
            default: parity_out = 8'h00;
        endcase
    end
    else begin
        case(parity_rd_idx)
            5'd0: parity_out=p[25];  5'd1: parity_out=p[24];
            5'd2: parity_out=p[23];  5'd3: parity_out=p[22];
            5'd4: parity_out=p[21];  5'd5: parity_out=p[20];
            5'd6: parity_out=p[19];  5'd7: parity_out=p[18];
            5'd8: parity_out=p[17];  5'd9: parity_out=p[16];
            5'd10: parity_out=p[15]; 5'd11: parity_out=p[14];
            5'd12: parity_out=p[13]; 5'd13: parity_out=p[12];
            5'd14: parity_out=p[11]; 5'd15: parity_out=p[10];
            5'd16: parity_out=p[9];  5'd17: parity_out=p[8];
            5'd18: parity_out=p[7];  5'd19: parity_out=p[6];
            5'd20: parity_out=p[5];  5'd21: parity_out=p[4];
            5'd22: parity_out=p[3];  5'd23: parity_out=p[2];
            5'd24: parity_out=p[1];  5'd25: parity_out=p[0];
            default: parity_out=8'h00;
        endcase
    end
end
endmodule
