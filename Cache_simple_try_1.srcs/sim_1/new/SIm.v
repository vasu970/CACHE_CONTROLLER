`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.06.2024 11:38:31
// Design Name: 
// Module Name: Test_cache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Test_cache();

 reg clk=0;
 reg reset;
 reg mode;
 reg [31:0] address;
 reg[31:0] Data;
 wire [31:0] out_Data; 
    
Cache_controller C1(clk,reset,mode,//mode is used to decide if its whether its read or write
address,
Data,
 out_Data);
 
 
 initial
 begin
 reset=0;
 #1 reset=1;
#1 reset =0;
#5 mode=0;//lets consider this as write mode for now
address=64;//write not hit
Data=16;
#100 mode=1;//read not hit
address=32;
Data=50;
#100 mode=1;
address=64;//read hit
Data=50;
#100 mode=0;
address=32;//write hit
Data=50;

#100 $finish;
 end
    always
    #5clk=~clk;
endmodule
