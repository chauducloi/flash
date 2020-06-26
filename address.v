
module address
 (
 // Declaration Input
 input                 sck,
 input                 clkm,
 input                 rst_n,
 input                 en_addr,
 input                 mode,
 input        [7:0]    addr_in,
 input                 en_write_buf,  // data buffer writing enable
 input                 en_read_buf,   // data buffer reading enable  
 input                 en_wr,         // memory writing enable 
 input                 save_start_addr, 
 // Declaration Output
 output  reg           program_clr,
 output  reg  [31:0]   addr,
 output  reg  [7:0]    wbyte_addr
 );

// Define
assign spi_mode = (!mode && en_addr);
assign opi_mode = ( mode && en_addr);

always@(posedge sck or negedge rst_n) 
begin
   if (!rst_n)
      addr <= 0;
   else if(spi_mode)                // Receive address in SPI mode
      addr <= {addr[30:0],addr_in[0]};
   else if (opi_mode)              // Receive address in OPI mode
      addr <= {addr[23:0],addr_in};
   else if(en_write_buf || en_read_buf) begin  //Data buffer address
      addr[7:0] <=  addr[7:0] + 8'd1;
   end
end 

always@(posedge clkm or negedge rst_n) 
begin
   if(!rst_n)
      wbyte_addr  = 8'h0;
   else if(save_start_addr)
      wbyte_addr  = addr[7:0];
   else if(en_wr)
      wbyte_addr  = wbyte_addr + 8'd1;     
end

always@(posedge clkm or negedge rst_n) 
begin
   if(!rst_n)
      program_clr = 1'b0;
   else if(en_wr && wbyte_addr==addr[7:0])
      program_clr = 1'b1;
   else 
      program_clr = 1'b0;     
end

endmodule 
