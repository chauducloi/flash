module interface_io
 (
  // Input 
  input                    en_send,
  input                    cs,
  input                    sck,
  input           [7:0]    data_out,
  // Output
  output    reg            ds,
  output          [7:0]    op_in,
  output          [7:0]    addr_in,
  output          [7:0]    data_in,
  // Inout
  inout     wire  [7:0]    i_o
 );

// regs & wires
reg  [7:0] out_value;

always@(*) 
begin
   if (en_send) begin 
      out_value  = data_out;
      ds         = ~sck;
   end
   else if (!cs) begin
      out_value  = 8'hz;
      ds         = 1'b0;
   end
   else begin
      out_value  = 8'hz; 
      ds         = 1'bz; 
   end
end

assign op_in     =  i_o;
assign addr_in   =  i_o;
assign data_in   =  i_o;
assign i_o       =  (en_send)?out_value:8'hz;

endmodule
