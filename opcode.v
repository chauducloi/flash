module opcode
 (
  // Input
  input                     sck,
  input                     mode,
  input                     rst_n,
  input           [7:0]     op_in,
  input                     en_opcode,
  // Output
  output   reg    [7:0]     op
);

// Reg & wire
wire   en_spi_mode;
wire   en_opi_mode;

// Define
assign spi_mode = (!mode && en_opcode);
assign opi_mode = ( mode && en_opcode);

always@(posedge sck or negedge rst_n) 
begin
   if(!rst_n)
      op <= 8'h00;
   else  begin
      if (spi_mode)                  // Receive OPCODE in SPI mode     
         op <= {op[6:0],op_in[0]}; 
      else if (opi_mode)               // Receive OPCODE in OPI mode
         op <= op_in;
   end
end 
endmodule
