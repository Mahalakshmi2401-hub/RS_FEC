//=====================================================
// PAYLOAD / PARITY COUNTERS
//=====================================================

module rs_fec_counters
(
    input  wire       clk,
    input  wire       rst_n,

    input  wire [7:0] payload_bytes,
    input  wire [4:0] parity_bytes,

    input  wire       payload_cnt_en,
    input  wire       parity_cnt_en,

    input  wire       cnt_clear,

    output wire       payload_done,
    output wire       parity_done,

    output reg        [4:0] parity_cnt
);
     reg              [7:0] payload_cnt;
//-----------------------------------------------------
// Done Detection
//-----------------------------------------------------

assign payload_done =
       payload_cnt_en &&
       (payload_cnt == payload_bytes-1);

assign parity_done =
       parity_cnt_en &&
       (parity_cnt == parity_bytes-1);

//-----------------------------------------------------
// Payload Counter
//-----------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        payload_cnt <= 8'd0;

    else if(cnt_clear)
        payload_cnt <= 8'd0;

    else if(payload_done)
        payload_cnt <= 8'd0;

    else if(payload_cnt_en)
        payload_cnt <= payload_cnt + 8'd1;
end

//-----------------------------------------------------
// Parity Counter
//-----------------------------------------------------

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        parity_cnt <= 5'd0;

    else if(cnt_clear)
        parity_cnt <= 5'd0;

    else if(parity_done)
        parity_cnt <= 5'd0;

    else if(parity_cnt_en)
        parity_cnt <= parity_cnt + 5'd1;
end


endmodule