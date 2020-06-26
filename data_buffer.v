module data_buffer
(
 input                sck,
 input                rst_n,
 input    [31:0]      addr,
 input    [7:0]       wbyte_addr,
 input    [7:0]       data_byte_in,
 input                en_write_buf,
 input                en_read_buf,
 input                en_wr,         
 output  reg  [7:0]   buf_out,
 output  reg  [7:0]   mem_data_in
 );

reg    [7:0]   buf_addr;
reg    [7:0]   d_buffer [0:255];
integer i;

always@(*)                                          // read buffer (D4H)
begin
   if(en_read_buf) begin
         buf_out   = d_buffer[addr[7:0]];    
      end         
   else begin 
      buf_out  = 0;
   end
end

always@(negedge sck or negedge rst_n) //write buffer 84H
begin 
   if(!rst_n) begin 
      for(i=0;i<=255;i=i+1) 
         d_buffer[i] <= 8'h00; 
   end
   else if(en_write_buf) begin 
         d_buffer[addr[7:0]]  <= data_byte_in;
   end
end

always@(*) // program
begin
   if(en_wr) // enable writing to memory
      mem_data_in = d_buffer[wbyte_addr];
   else 
      mem_data_in = 8'h00; 
end
endmodule
