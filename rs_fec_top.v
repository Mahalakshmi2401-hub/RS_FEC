`timescale 1ns/1ps
//=====================================================
// RS-FEC TOP
//=====================================================
module rs_fec_top
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] d_plp_tx,
    input  wire       d_plp_tx_valid,
    input  wire [2:0] speed_grade,
    output reg  [7:0] tx_phy_block,
    output reg        tx_phy_block_valid
);

    // Configuration
     wire [7:0] payload_bytes;
     wire [4:0] parity_bytes;

  // Counters
     wire payload_done;
     wire parity_done;
     wire parity_cnt_en;
     wire parity_clear;
     wire [4:0] parity_cnt;
     wire fifo_data_valid;
     wire live_data_valid;

   // FIFO
      wire fifo_wr_en;
      wire fifo_rd_en;
      wire fifo_wr_en_fsm;
      wire fifo_rd_en_fsm;
      wire [7:0] fifo_dout;
      wire fifo_empty;
      wire fifo_full;

   // Parity
      wire [7:0] parity_out;
      wire sel_out;
      wire [7:0] current_data;
      wire use_fifo;
      wire payload_cnt_en_int;
    
//-----------------------------------------------------
// Config
//-----------------------------------------------------

   rs_fec_config u_cfg
   (
    .speed_grade(speed_grade),
    .payload_bytes(payload_bytes),
    .parity_bytes(parity_bytes)
   );
   
   rs_fec_counters u_cnt
   (
    .clk(clk),
    .rst_n(rst_n),
    .payload_bytes(payload_bytes),
    .parity_bytes(parity_bytes),
    .cnt_clear(parity_clear),
    .payload_done(payload_done),
    .parity_cnt(parity_cnt),
    .payload_cnt_en(payload_cnt_en_int),
    .parity_cnt_en(parity_cnt_en),
    .parity_done(parity_done)
    );

//-----------------------------------------------------
// FSM
//-----------------------------------------------------

    rs_fec_fsm u_fsm
    (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .d_plp_tx_valid(d_plp_tx_valid),
    .payload_done(payload_done),
    .parity_done(parity_done),
    .fifo_empty(fifo_empty),
    .parity_cnt_en(parity_cnt_en),
    .parity_bytes(parity_bytes),
    .fifo_wr_en(fifo_wr_en_fsm),
    .fifo_rd_en(fifo_rd_en_fsm),
    .parity_clear(parity_clear),
    .sel_out(sel_out),
    .use_fifo(use_fifo)
    );
    
    rs_parity_engine u_parity
    (
    .clk(clk),
    .rst_n(rst_n),
    .current_data(current_data),
    .data_valid(fifo_data_valid | live_data_valid),
    .parity_bytes(parity_bytes),
    .parity_clear(parity_clear),
    .parity_rd_idx(parity_cnt),
    .parity_out(parity_out)
    );
    
    rs_fec_fifo
    #(
    .DEPTH(64),
    .ADDR_W(6)
    )
    u_fifo
    (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(fifo_wr_en),
    .din(d_plp_tx),
    .full(fifo_full),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .empty(fifo_empty)
    );
    //-----------------------------------------------------
// Source Selection
//-----------------------------------------------------

assign current_data =
use_fifo ?
fifo_dout :
d_plp_tx;

assign payload_cnt_en_int =
       fifo_data_valid |
       live_data_valid;

//-----------------------------------------------------
// FIFO Control
//-----------------------------------------------------

assign fifo_wr_en = fifo_wr_en_fsm && d_plp_tx_valid && !fifo_full;

assign fifo_rd_en =
       fifo_rd_en_fsm &&
       !fifo_empty;
//-----------------------------------------------------
// Output Path
//-----------------------------------------------------

wire [7:0] mux_out;
wire       mux_valid;

assign mux_out = sel_out ? parity_out : current_data;

assign live_data_valid =
       !use_fifo &&
       d_plp_tx_valid;

assign fifo_data_valid =
       use_fifo &&
       !fifo_empty;

assign mux_valid = sel_out ? parity_cnt_en : (fifo_data_valid | live_data_valid);

reg mux_valid_d;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        mux_valid_d <= 1'b0;
    else
        mux_valid_d <= mux_valid;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_phy_block       <= 8'h00;
        tx_phy_block_valid <= 1'b0;
    end
    else
    begin
        tx_phy_block       <= mux_out;
        tx_phy_block_valid <= mux_valid_d;
    end
end
endmodule