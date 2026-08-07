`timescale 1ns/1ps

//=====================================================
// RS-FEC FSM
//=====================================================

module rs_fec_fsm
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       start,
    input  wire       d_plp_tx_valid,

    input  wire       payload_done,
    input  wire       parity_done,

    input  wire       fifo_empty,

    input  wire [4:0] parity_bytes,

    output reg        parity_cnt_en,

    output reg        fifo_wr_en,
    output reg        fifo_rd_en,

    output reg        parity_clear,

    output reg        sel_out,
    output reg        use_fifo
);

//=====================================================
// State Definitions
//=====================================================

localparam IDLE            = 3'd0;
localparam CLEAR_PARITY    = 3'd1;
localparam RECEIVE_PAYLOAD = 3'd2;
localparam OUTPUT_PARITY   = 3'd3;
localparam PROCESS_FIFO    = 3'd4;

reg [2:0] state;
reg [2:0] next_state;

//=====================================================
// FIFO Byte Counter
//=====================================================

reg [4:0] fifo_byte_cnt;

//=====================================================
// State Register
//=====================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

//=====================================================
// FIFO Byte Counter
//=====================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        fifo_byte_cnt <= 5'd0;
    end
    else if(state != PROCESS_FIFO)
    begin
        fifo_byte_cnt <= 5'd0;
    end
    else if(fifo_rd_en && !fifo_empty)
    begin
        fifo_byte_cnt <= fifo_byte_cnt + 5'd1;
    end
end

//=====================================================
// Next-State Logic
//=====================================================

always @(*)
begin

    // Default: remain in current state
    next_state = state;

    case(state)

        //-------------------------------------------------
        // IDLE
        //-------------------------------------------------

        IDLE:
        begin
            if(start)
                next_state = CLEAR_PARITY;
        end

        //-------------------------------------------------
        // Clear parity registers and counters
        //-------------------------------------------------

        CLEAR_PARITY:
        begin
            next_state = RECEIVE_PAYLOAD;
        end

        //-------------------------------------------------
        // Receive Payload
        //-------------------------------------------------

        RECEIVE_PAYLOAD:
        begin
            if(payload_done)
                next_state = OUTPUT_PARITY;
        end

        //-------------------------------------------------
        // Output Parity
        //-------------------------------------------------

        OUTPUT_PARITY:
        begin
            if(parity_done)
            begin
                if(!fifo_empty)
                    next_state = PROCESS_FIFO;
                else
                    next_state = CLEAR_PARITY;
            end
        end

        //-------------------------------------------------
        // Process bytes buffered during parity output
        //-------------------------------------------------

        PROCESS_FIFO:
        begin
            if(fifo_empty)
                next_state = CLEAR_PARITY;

            else if(fifo_byte_cnt == (parity_bytes - 1'b1))
                next_state = CLEAR_PARITY;
        end

        //-------------------------------------------------
        // Safety
        //-------------------------------------------------

        default:
        begin
            next_state = IDLE;
        end

    endcase

end

//=====================================================
// Output Logic
//=====================================================

always @(*)
begin

    //-------------------------------------------------
    // Default Outputs
    //-------------------------------------------------

    parity_cnt_en = 1'b0;

    fifo_wr_en    = 1'b0;
    fifo_rd_en    = 1'b0;

    parity_clear  = 1'b0;

    sel_out       = 1'b0;
    use_fifo      = 1'b0;

    case(state)

        //-------------------------------------------------
        // IDLE
        //-------------------------------------------------

        IDLE:
        begin
            // Wait for start
        end

        //-------------------------------------------------
        // Clear Parity
        //-------------------------------------------------

        CLEAR_PARITY:
        begin
            // Clears:
            //   - parity registers
            //   - payload counter
            //   - parity counter

            parity_clear = 1'b1;
        end

        //-------------------------------------------------
        // Receive Live Payload
        //-------------------------------------------------

        RECEIVE_PAYLOAD:
        begin
            use_fifo = 1'b0;
            sel_out  = 1'b0;
        end

        //-------------------------------------------------
        // Output Parity
        //-------------------------------------------------

        OUTPUT_PARITY:
        begin

            // Select parity output
            sel_out = 1'b1;

            // Enable parity output counter
            parity_cnt_en = 1'b1;

            // Store incoming next-frame bytes
            // while parity is being transmitted
            if(d_plp_tx_valid)
                fifo_wr_en = 1'b1;

        end

        //-------------------------------------------------
        // Process FIFO Data
        //-------------------------------------------------

        PROCESS_FIFO:
        begin

            // Select FIFO as payload source
            use_fifo = 1'b1;

            // Payload output selected
            sel_out = 1'b0;

            // Read FIFO only when data exists
            if(!fifo_empty)
                fifo_rd_en = 1'b1;

        end

        //-------------------------------------------------
        // Safety
        //-------------------------------------------------

        default:
        begin
            parity_cnt_en = 1'b0;
            fifo_wr_en    = 1'b0;
            fifo_rd_en    = 1'b0;
            parity_clear  = 1'b0;
            sel_out       = 1'b0;
            use_fifo      = 1'b0;
        end

    endcase

end

endmodule