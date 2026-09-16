`timescale 1ns/1ps
// Large FIFO is intentional:
// at RS(240,214), output is 240 bytes/block while input
// is 214 bytes/block. A 64-byte FIFO cannot absorb 100
// continuously supplied packets.
module rs_fec_fifo
#(
    parameter DEPTH  = 4096,
    parameter ADDR_W = 12
)
(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wr_en,
    input  wire [7:0]  din,
    input  wire        din_last,
    output wire        full,
    input  wire        rd_en,
    output wire [7:0]  dout,
    output wire        dout_last,
    output wire        empty,
    output wire [12:0] count
);

reg [8:0] mem [0:DEPTH-1];
reg [ADDR_W:0] wr_ptr;
reg [ADDR_W:0] rd_ptr;
reg [ADDR_W:0] count_r;

wire [ADDR_W-1:0] wr_addr = wr_ptr[ADDR_W-1:0];
wire [ADDR_W-1:0] rd_addr = rd_ptr[ADDR_W-1:0];

assign empty    = (count_r == 0);
assign full     = (count_r == DEPTH);
assign count    = count_r;
assign dout     = mem[rd_addr][7:0];
assign dout_last = mem[rd_addr][8];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wr_ptr  <= {(ADDR_W+1){1'b0}};
        rd_ptr  <= {(ADDR_W+1){1'b0}};
        count_r <= {(ADDR_W+1){1'b0}};
    end
    else begin
        if(wr_en && !full) begin
            mem[wr_addr] <= {din_last,din};
            wr_ptr <= wr_ptr + 1'b1;
        end

        if(rd_en && !empty)
            rd_ptr <= rd_ptr + 1'b1;

        case ({(wr_en && !full),(rd_en && !empty)})
            2'b10: count_r <= count_r + 1'b1;
            2'b01: count_r <= count_r - 1'b1;
            default: count_r <= count_r;
        endcase
    end
end
endmodule
