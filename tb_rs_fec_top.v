`timescale 1ns/1ps

module tb_rs_fec_top;

reg clk, rst_n;
reg start, fec_last;
reg [7:0] d_plp_tx;
reg d_plp_tx_valid;
reg [2:0] speed_grade;

wire fec_en, fec_done;
wire [7:0] tx_phy_block;
wire tx_phy_block_valid;

parameter NUM_PACKETS       = 100;
parameter INPUT_PACKET_BYTES = 214;
parameter MAX_PAYLOAD_BYTES = 214;
parameter MAX_PARITY_BYTES  = 26;
parameter MAX_OUTPUT_BYTES  = 240;

parameter INPUT_BYTES  = NUM_PACKETS * INPUT_PACKET_BYTES;
parameter MAX_EXPECTED = NUM_PACKETS * MAX_OUTPUT_BYTES;

reg [7:0] input_mem [0:INPUT_BYTES-1];
reg [7:0] expected_mem [0:MAX_EXPECTED-1];

integer i, pkt, base_index;
integer payload_bytes, parity_bytes, expected_bytes;
integer output_count, error_count, fec_done_count;
integer timeout_count;
reg [8*80:1] expected_file;

rs_fec_top DUT (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .fec_last(fec_last),
    .d_plp_tx(d_plp_tx),
    .d_plp_tx_valid(d_plp_tx_valid),
    .speed_grade(speed_grade),
    .fec_en(fec_en),
    .fec_done(fec_done),
    .tx_phy_block(tx_phy_block),
    .tx_phy_block_valid(tx_phy_block_valid)
);

always #5 clk = ~clk;

always @(posedge clk) begin
    if(tx_phy_block_valid) begin
        if(output_count < expected_bytes) begin
            if(tx_phy_block !== expected_mem[output_count]) begin
                $display("[%0t] ERROR SG=%03b OUT[%0d] EXP=%02h GOT=%02h",$time, speed_grade, output_count,expected_mem[output_count], tx_phy_block);
                error_count = error_count + 1;
            end
        end
        output_count = output_count + 1;
    end

    if(fec_done)
        fec_done_count = fec_done_count + 1;
end

task get_config;
input [2:0] sg;
begin
    case(sg)
        3'b000,3'b001: begin payload_bytes=214; parity_bytes=2;  end
        3'b010,3'b011,3'b100: begin payload_bytes=214; parity_bytes=26; end
        3'b101,3'b110: begin payload_bytes=106; parity_bytes=2; end
        default: begin payload_bytes=214; parity_bytes=2; end
    endcase
    expected_bytes = NUM_PACKETS * (payload_bytes + parity_bytes);
end
endtask

task load_expected;
input [2:0] sg;
begin
    case(sg)
        3'b000: expected_file="fec_expected_sg000_100pkt.mem";
        3'b001: expected_file="fec_expected_sg001_100pkt.mem";
        3'b010: expected_file="fec_expected_sg010_100pkt.mem";
        3'b011: expected_file="fec_expected_sg011_100pkt.mem";
        3'b100: expected_file="fec_expected_sg100_100pkt.mem";
        3'b101: expected_file="fec_expected_sg101_100pkt.mem";
        3'b110: expected_file="fec_expected_sg110_100pkt.mem";
        default: expected_file="fec_expected_sg111_100pkt.mem";
    endcase

    $readmemh(expected_file, expected_mem);
end
endtask

task reset_dut;
begin
    rst_n = 1'b0;
    start = 1'b0;
    fec_last = 1'b0;
    d_plp_tx_valid = 1'b0;
    d_plp_tx = 8'h00;
    repeat(5) @(negedge clk);
    rst_n = 1'b1;
    repeat(2) @(negedge clk);
end
endtask

task run_speed_grade;
input [2:0] sg;
begin
    get_config(sg);
    load_expected(sg);

    speed_grade = sg;
    output_count = 0;
    error_count = 0;
    fec_done_count = 0;

    reset_dut;

    $display("");
    $display("============================================================");
    $display("STARTING SPEED GRADE = %03b", sg);
    $display("============================================================");
    $display("Payload Bytes        = %0d", payload_bytes);
    $display("Parity Bytes         = %0d", parity_bytes);
    $display("Bytes / RS Block     = %0d", payload_bytes+parity_bytes);
    $display("Packets              = %0d", NUM_PACKETS);
    $display("Expected Outputs     = %0d", expected_bytes);
    $display("Expected File        = %0s", expected_file);

    // Start FEC. Input is driven on negedge; DUT samples on posedge.
    @(negedge clk);
    start = 1'b1;
    @(negedge clk);
    start = 1'b0;

    // Continuous input stream. The input file ALWAYS has a 214-byte
    // stride per packet, even for SG101/SG110.
    for(pkt=0; pkt<NUM_PACKETS; pkt=pkt+1) begin
        base_index = pkt * INPUT_PACKET_BYTES;

        for(i=0; i<payload_bytes; i=i+1) begin
            @(negedge clk);
            d_plp_tx = input_mem[base_index+i];
            d_plp_tx_valid = 1'b1;

            if((pkt == NUM_PACKETS-1) &&
               (i == payload_bytes-1))
                fec_last = 1'b1;
            else
                fec_last = 1'b0;
        end
    end

    @(negedge clk);
    d_plp_tx_valid = 1'b0;
    d_plp_tx = 8'h00;
    fec_last = 1'b0;

    // Wait for exactly one FEC_DONE, with timeout.
    timeout_count = 0;
    while((fec_done_count == 0) && (timeout_count < 200000)) begin
        @(negedge clk);
        timeout_count = timeout_count + 1;
    end

    if(fec_done_count == 0)
        $display("TIMEOUT waiting for FEC_DONE");

    // Allow final output-valid observation.
    repeat(10) @(negedge clk);

    $display("SG=%03b Errors=%0d Outputs=%0d FEC_DONE=%0d",
             sg,error_count,output_count,fec_done_count);

    if((error_count == 0) &&
       (output_count == expected_bytes) &&
       (fec_done_count == 1))
        $display("SG=%03b : PASS",sg);
    else
        $display("SG=%03b : FAIL",sg);
end
endtask

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    fec_last = 1'b0;
    d_plp_tx = 8'h00;
    d_plp_tx_valid = 1'b0;
    speed_grade = 3'b000;

    $display("Loading input memory...");
    $readmemh("fec_input_100pkt.mem", input_mem);
    $display("Input memory loaded: %0d bytes", INPUT_BYTES);

    run_speed_grade(3'b000);
    run_speed_grade(3'b001);
    run_speed_grade(3'b010);
    run_speed_grade(3'b011);
    run_speed_grade(3'b100);
    run_speed_grade(3'b101);
    run_speed_grade(3'b110);
    run_speed_grade(3'b111);

    $display("");
    $display("============================================================");
    $display("FINAL ALL SPEED-GRADE SUMMARY");
    $display("============================================================");
    $display("Simulation completed.");
    $display("============================================================");

    $finish;
end

endmodule
