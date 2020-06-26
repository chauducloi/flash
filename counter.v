module counter
 (
  input                  sck,
  input                  cs,
  input                  clr_count,
  output   reg   [4:0]   count
 );         

wire   clk;
always@(posedge sck or posedge cs) 
begin
   if (cs)
      count  <= 5'd0;
   else if (clr_count)
      count  <= 5'd0;
   else 
      count  <= count + 1'b1;
end

endmodule
