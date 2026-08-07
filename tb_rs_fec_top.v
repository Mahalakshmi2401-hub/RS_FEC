`timescale 1ns/1ps

module tb_rs_fec_top;

//----------------------------------------------------
// DUT Inputs
//----------------------------------------------------

reg         clk;
reg         rst_n;
reg         start;
reg  [7:0]  d_plp_tx;
reg         d_plp_tx_valid;
reg  [2:0]  speed_grade;

//----------------------------------------------------
// DUT Outputs
//----------------------------------------------------

wire [7:0]  tx_phy_block;
wire        tx_phy_block_valid;

//----------------------------------------------------
// Parameters
//----------------------------------------------------

parameter PAYLOAD_BYTES  = 214;
parameter PARITY_BYTES   = 26;
parameter NUM_PACKETS    = 100;

parameter INPUT_BYTES    = PAYLOAD_BYTES * NUM_PACKETS;
parameter EXPECTED_BYTES = (PAYLOAD_BYTES + PARITY_BYTES) * NUM_PACKETS;

//----------------------------------------------------
// Memories
//----------------------------------------------------

reg [7:0] input_mem    [0:INPUT_BYTES-1];
reg [7:0] expected_mem [0:EXPECTED_BYTES-1];

//----------------------------------------------------
// Variables
//----------------------------------------------------

integer pkt;
integer i;

integer total_tx_bytes;

integer output_count;
integer error_count;

//----------------------------------------------------
// DUT
//----------------------------------------------------

rs_fec_top DUT
(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .d_plp_tx(d_plp_tx),
    .d_plp_tx_valid(d_plp_tx_valid),
    .speed_grade(speed_grade),
    .tx_phy_block(tx_phy_block),
    .tx_phy_block_valid(tx_phy_block_valid)
);

//----------------------------------------------------
// Clock Generation
//----------------------------------------------------

initial
begin
    clk = 1'b0;

    forever
        #5 clk = ~clk;
end

//----------------------------------------------------
// Waveform Dump
//----------------------------------------------------

initial
begin
    $dumpfile("rs_fec.vcd");
    $dumpvars(0,tb_rs_fec_top);
end

//----------------------------------------------------
// Output Checker
//----------------------------------------------------

always @(posedge clk)
begin
    #1;
    if(tx_phy_block_valid)
    begin

        if(output_count < EXPECTED_BYTES)
        begin

            if(tx_phy_block !== expected_mem[output_count])
            begin

                $display(
                "[%0t] ERROR OUT[%0d] EXP=%02h GOT=%02h",
                $time,
                output_count,
                expected_mem[output_count],
                tx_phy_block
                );

                error_count = error_count + 1;

            end
            else
            begin

                $display(
                "[%0t] PASS OUT[%0d] DATA=%02h",
                $time,
                output_count,
                tx_phy_block
                );

            end

            output_count = output_count + 1;

        end
        else
        begin

            $display(
            "[%0t] ERROR: EXTRA OUTPUT BYTE = %02h",
            $time,
            tx_phy_block
            );

            error_count = error_count + 1;

        end

    end

end

//----------------------------------------------------
// Main Test
//----------------------------------------------------

initial
begin

    //------------------------------------------------
    // Initialize
    //------------------------------------------------

    rst_n             = 1'b0;
    start             = 1'b0;
    d_plp_tx          = 8'h00;
    d_plp_tx_valid    = 1'b0;

    speed_grade       = 3'b010;

    total_tx_bytes    = 0;

    output_count      = 0;
    error_count       = 0;

    //------------------------------------------------
    // Load Memories
    //------------------------------------------------

    $readmemh(
        "fec_input_100pkt.mem",
        input_mem
    );

    $readmemh(
        "fec_expected_100pkt.mem",
        expected_mem
    );

    //------------------------------------------------
    // Reset
    //------------------------------------------------

    repeat(5)
        @(posedge clk);

    rst_n = 1'b1;

    repeat(10)
        @(posedge clk);

    //------------------------------------------------
    // Start DUT
    //------------------------------------------------

    @(negedge clk);
    start = 1'b1;

    @(negedge clk);
    start = 1'b0;

    //------------------------------------------------
    // Send Continuous Stream
    //------------------------------------------------

    d_plp_tx_valid = 1'b1;

    for(pkt = 0; pkt < NUM_PACKETS; pkt = pkt + 1)
    begin

        for(i = 0; i < PAYLOAD_BYTES; i = i + 1)
        begin

            @(negedge clk);

            d_plp_tx =
                input_mem[(pkt * PAYLOAD_BYTES) + i];

            total_tx_bytes =
                total_tx_bytes + 1;

        end

    end

    //------------------------------------------------
    // Stop Input
    //------------------------------------------------

    @(negedge clk);

    d_plp_tx_valid = 1'b0;
    d_plp_tx       = 8'h00;

    //------------------------------------------------
    // Wait For Outputs
    //------------------------------------------------

    wait(output_count == EXPECTED_BYTES);

    repeat(20)
        @(posedge clk);

    //------------------------------------------------
    // Summary
    //------------------------------------------------

    $display("");
    $display("======================================");
    $display("RS-FEC CONTINUOUS STREAM TEST");
    $display("======================================");

    $display(
        "Packets Sent      = %0d",
        NUM_PACKETS
    );

    $display(
        "Input Bytes       = %0d",
        total_tx_bytes
    );

    $display(
        "Expected Outputs  = %0d",
        EXPECTED_BYTES
    );

    $display(
        "Received Outputs  = %0d",
        output_count
    );

    $display(
        "Errors            = %0d",
        error_count
    );

    if(error_count == 0)
        $display("TEST PASS");
    else
        $display("TEST FAIL");

    $display("======================================");
    $display("");

    #100;

    $finish;

end

endmodule