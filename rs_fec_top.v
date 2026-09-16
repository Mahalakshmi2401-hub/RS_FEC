`timescale 1ns/1ps

module rs_fec_top
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire       fec_last,
    input  wire [7:0] d_plp_tx,
    input  wire       d_plp_tx_valid,
    input  wire [2:0] speed_grade,
    output wire       fec_en,
    output wire       fec_done,
    output reg  [7:0] tx_phy_block,
    output reg        tx_phy_block_valid
);

wire [7:0] payload_bytes;
wire [4:0] parity_bytes;

rs_fec_config u_config (
    .speed_grade(speed_grade),
    .payload_bytes(payload_bytes),
    .parity_bytes(parity_bytes)
);

wire payload_cnt_en;
wire parity_cnt_en;
wire payload_done;
wire parity_done;
wire [4:0] parity_cnt;
wire cnt_clear;
wire parity_clear;

assign cnt_clear = parity_clear;

wire fifo_wr_en_fsm;
wire fifo_rd_en_fsm;
wire fifo_wr_en;
wire fifo_rd_en;
wire fifo_empty;
wire fifo_full;
wire [7:0] fifo_dout;
wire fifo_dout_last;
wire [12:0] fifo_count;

rs_fec_fifo #(
    .DEPTH(4096),
    .ADDR_W(12)
) u_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(fifo_wr_en),
    .din(d_plp_tx),
    .din_last(fec_last),
    .full(fifo_full),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .dout_last(fifo_dout_last),
    .empty(fifo_empty),
    .count(fifo_count)
);

assign fifo_wr_en = fifo_wr_en_fsm && d_plp_tx_valid && !fifo_full;
assign fifo_rd_en = fifo_rd_en_fsm && !fifo_empty;

wire sel_out;
wire use_fifo;

wire [7:0] current_data;
wire current_last;

assign current_data = use_fifo ? fifo_dout : d_plp_tx;
assign current_last = use_fifo ? fifo_dout_last : fec_last;

wire [7:0] parity_out;
wire [4:0] parity_rd_idx;

assign parity_rd_idx = parity_cnt;

wire payload_data_valid;

assign payload_data_valid = use_fifo && !fifo_empty && payload_cnt_en;

rs_parity_engine u_parity (
    .clk(clk),
    .rst_n(rst_n),
    .current_data(current_data),
    .data_valid(payload_data_valid),
    .parity_bytes(parity_bytes),
    .parity_clear(parity_clear),
    .parity_rd_idx(parity_rd_idx),
    .parity_out(parity_out)
);

rs_fec_counters u_counters (
    .clk(clk),
    .rst_n(rst_n),
    .payload_bytes(payload_bytes),
    .parity_bytes(parity_bytes),
    .payload_cnt_en(payload_cnt_en),
    .parity_cnt_en(parity_cnt_en),
    .cnt_clear(cnt_clear),
    .payload_done(payload_done),
    .parity_done(parity_done),
    .parity_cnt(parity_cnt)
);

// Latches the end marker belonging to the payload currently
// being processed. It is taken from the last payload FIFO word.
reg block_last;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        block_last <= 1'b0;
    else if(parity_clear)
        block_last <= 1'b0;
    else if(payload_done)
        block_last <= current_last;
end

rs_fec_fsm u_fsm (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .d_plp_tx_valid(d_plp_tx_valid),
    .fifo_count(fifo_count),
    .payload_bytes(payload_bytes),
    .payload_done(payload_done),
    .parity_done(parity_done),
    .block_last(block_last),
    .fec_en(fec_en),
    .fec_done(fec_done),
    .payload_cnt_en(payload_cnt_en),
    .parity_cnt_en(parity_cnt_en),
    .fifo_wr_en(fifo_wr_en_fsm),
    .fifo_rd_en(fifo_rd_en_fsm),
    .parity_clear(parity_clear),
    .sel_out(sel_out),
    .use_fifo(use_fifo)
);

wire [7:0] mux_out;
wire mux_valid;

assign mux_out = sel_out ? parity_out : current_data;
assign mux_valid = sel_out ? parity_cnt_en : (use_fifo && !fifo_empty && payload_cnt_en);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_phy_block       <= 8'h00;
        tx_phy_block_valid <= 1'b0;
    end
    else begin
        tx_phy_block_valid <= mux_valid;
        if(mux_valid)
            tx_phy_block <= mux_out;
    end
end

endmodule
