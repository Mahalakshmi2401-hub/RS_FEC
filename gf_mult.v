`timescale 1ns/1ps
module gf_mult
(
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] product
);
function [7:0] gf8_mult;
    input [7:0] aa;
    input [7:0] bb;
    reg [7:0] a_tmp;
    reg [7:0] b_tmp;
    reg [7:0] p;
    integer i;
    begin
        a_tmp = aa;
        b_tmp = bb;
        p = 8'h00;
        for(i=0;i<8;i=i+1) begin
            if(b_tmp[0])
                p = p ^ a_tmp;
            if(a_tmp[7])
                a_tmp = (a_tmp << 1) ^ 8'h1D;
            else
                a_tmp = (a_tmp << 1);
            b_tmp = b_tmp >> 1;
        end
        gf8_mult = p;
    end
endfunction
assign product = gf8_mult(a,b);
endmodule
