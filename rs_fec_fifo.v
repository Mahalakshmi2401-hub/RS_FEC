module rs_fec_fifo
#(
    parameter DEPTH  = 64,
    parameter ADDR_W = 6
)
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       wr_en,
    input  wire [7:0] din,
    output wire       full,
    input  wire       rd_en,
    output wire [7:0] dout,
    output wire       empty
);

reg [7:0] mem [0:DEPTH-1];

reg [ADDR_W:0] wr_ptr;
reg [ADDR_W:0] rd_ptr;

wire [ADDR_W-1:0] wr_addr;
wire [ADDR_W-1:0] rd_addr;

assign wr_addr = wr_ptr[ADDR_W-1:0];
assign rd_addr = rd_ptr[ADDR_W-1:0];

assign empty = (wr_ptr == rd_ptr);

assign full =
       (wr_ptr ==
       {~rd_ptr[ADDR_W],
         rd_ptr[ADDR_W-1:0]});

always @(posedge clk)
begin
    if(wr_en && !full)
        mem[wr_addr] <= din;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        wr_ptr <= 0;
    else if(wr_en && !full)
        wr_ptr <= wr_ptr + 1'b1;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        rd_ptr <= 0;
    else if(rd_en && !empty)
        rd_ptr <= rd_ptr + 1'b1;
end

assign dout = mem[rd_addr];

endmodule