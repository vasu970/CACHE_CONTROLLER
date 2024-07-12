`timescale 1ns / 1ps
module mem
#(
  parameter WIDTH = 8,
  parameter DEPTH = 64
)
(
  input  wire                 clock,input reset,
  input  wire [(4*WIDTH)-1:0]     data,
  input  wire [$clog2(DEPTH)-1:0] rdaddress,
  input  wire                 rden,
  input  wire [$clog2(DEPTH)-1:0] wraddress,
  input  wire                 wren,
  output reg  [(4*WIDTH)-1:0]     q
);
integer i=0;
  reg [WIDTH-1:0] mem [0:DEPTH-1] /* synthesis ramstyle = "M20K" */;
always@(negedge reset)
begin
      if (reset==0)
      begin
        for (i = 0; i < DEPTH; i = i +1)
         mem[i] <= i;
      end
   end

  always @ (posedge clock)
  begin
    if (wren)
      mem[wraddress] <= data[7:0];
      mem[wraddress+1] <= data[15:8];
      mem[wraddress+2] <= data[23:16];
      mem[wraddress+3] <= data[31:24];
  end

  always @ (posedge clock)
  begin
    if (rden)
      q <= {mem[rdaddress+3],mem[rdaddress+2],mem[rdaddress+1],mem[rdaddress]};
  end
endmodule
