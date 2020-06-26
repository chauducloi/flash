
module sector_protection
 (
  // Input
  input              cs,
  input              rst_n,
  input     [31:0]   addr,
  input              prot,
  input              unprot,
  input              r_sector,
  // Output
  output    [7:0]    prot_data_out,
  output             protect_signal
 );

// Reg & wire
reg  [15:0] sec_register;     
wire [3:0]  sec_addr;                              // 4 bits of Sector Address

// Define
assign sec_addr       =   addr[21:18];

// Read Sector Protection Register
assign protect_signal =  sec_register[sec_addr];          // protect sector signal
assign prot_data_out  =  sec_register[sec_addr]? 8'hFF:8'h00;//output to data buffer
// Write Sector Protection Register
always@(posedge cs or negedge rst_n) 
begin
   if(!rst_n)
      sec_register  <= 16'hFFFF;
   else if(prot)
      sec_register[sec_addr]  <= 1'b1; 
   else if(unprot)
      sec_register[sec_addr]  <= 1'b0; 
end
endmodule
