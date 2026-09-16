`timescale 1ns/1ps

//=====================================================
// RS-FEC block scheduler
// A complete payload is accumulated in the large FIFO.
// The FSM never uses parity_bytes as the payload length.
//=====================================================
module rs_fec_fsm
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire       d_plp_tx_valid,
    input  wire       [12:0] fifo_count,
    input  wire       [7:0]  payload_bytes,
    input  wire       payload_done,
    input  wire       parity_done,
    input  wire       block_last,
    output reg        fec_en,
    output reg        fec_done,
    output reg        payload_cnt_en,
    output reg        parity_cnt_en,
    output reg        fifo_wr_en,
    output reg        fifo_rd_en,
    output reg        parity_clear,
    output reg        sel_out,
    output reg        use_fifo
);

localparam IDLE            = 3'd0;
localparam WAIT_BLOCK      = 3'd1;
localparam CLEAR_PARITY    = 3'd2;
localparam PROCESS_PAYLOAD = 3'd3;
localparam OUTPUT_PARITY   = 3'd4;
localparam FEC_DONE_STATE  = 3'd5;

reg [2:0] state;
reg [2:0] next_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    next_state = state;

    case(state)
        IDLE:
            if(start)
                next_state = WAIT_BLOCK;

        WAIT_BLOCK:
            if(fifo_count >= {5'd0,payload_bytes})
                next_state = CLEAR_PARITY;

        CLEAR_PARITY:
            next_state = PROCESS_PAYLOAD;

        PROCESS_PAYLOAD:
            if(payload_done)
                next_state = OUTPUT_PARITY;

        OUTPUT_PARITY:
            if(parity_done) begin
                if(block_last)
                    next_state = FEC_DONE_STATE;
                else
                    next_state = WAIT_BLOCK;
            end

        FEC_DONE_STATE:
            next_state = IDLE;

        default:
            next_state = IDLE;
    endcase
end

always @(*) begin
    fec_en        = 1'b0;
    fec_done      = 1'b0;
    payload_cnt_en = 1'b0;
    parity_cnt_en  = 1'b0;
    fifo_wr_en     = 1'b0;
    fifo_rd_en     = 1'b0;
    parity_clear   = 1'b0;
    sel_out        = 1'b0;
    use_fifo       = 1'b0;

    case(state)
        IDLE: begin
            fec_en = 1'b0;
        end

        WAIT_BLOCK: begin
            fec_en    = 1'b1;
            fifo_wr_en = d_plp_tx_valid;
        end

        CLEAR_PARITY: begin
            fec_en      = 1'b1;
            parity_clear = 1'b1;
            fifo_wr_en   = d_plp_tx_valid;
        end

        PROCESS_PAYLOAD: begin
            fec_en         = 1'b1;
            use_fifo       = 1'b1;
            payload_cnt_en = 1'b1;
            fifo_rd_en     = 1'b1;
            fifo_wr_en     = d_plp_tx_valid;
        end

        OUTPUT_PARITY: begin
            fec_en        = 1'b1;
            sel_out       = 1'b1;
            parity_cnt_en = 1'b1;
            fifo_wr_en    = d_plp_tx_valid;
        end

        FEC_DONE_STATE: begin
            fec_en   = 1'b0;
            fec_done = 1'b1;
        end

        default: begin
        end
    endcase
end
endmodule
