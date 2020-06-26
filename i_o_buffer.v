
module i_o_buffer
 (
  // Declaration Input
  input                   sck,
  input                   rst_n,
  input                   mode,
  input          [7:0]    data_in,
  
  input                   read_mem,
  input                   read_mem_valid,
  input          [7:0]    mem_data_out,

  input          [7:0]    sc_data_out,   // Status/Control Registers
  input                   sc_out_valid,
  input                   sc_en,

  input          [7:0]    prot_data_out, // Sector Protection Registers

  input          [7:0]    buf_out,       // Data Buffer
  input                   buf_out_valid,
  input                   r_buffer,

  input                   r_sector,
  input                   en_rec,
  input                   en_send,
  // Declaration Output
  output   reg   [7:0]    data_out,
  output   reg   [7:0]    data_byte_in
);

// Regs & wires
reg     [7:0]    storage;
wire    [7:0]    data_byte_out;
       
// Define
assign spi_receive    = !mode && en_rec;
assign opi_receive    =  mode && en_rec;  
assign spi_send       = !mode && en_send;
assign opi_send       =  mode && en_send;


assign data_byte_out  =  sc_en    ? sc_data_out:
                         r_sector ? prot_data_out:
                         r_buffer ? buf_out:
                         read_mem    ? mem_data_out: 0;

assign data_out_valid =  sc_out_valid || r_sector || buf_out_valid || read_mem_valid;
always@(posedge sck or negedge rst_n) //Receiving Data
begin
   if(!rst_n) begin
      data_byte_in   <= 8'h00;
   end 
   else if (spi_receive) begin                  // Receive data in SPI mode
      data_byte_in   <= {data_byte_in[6:0],data_in[0]};
   end
   else if (opi_receive) begin                  // Receive data in OPI mode
      data_byte_in   <= data_in;
   end
end
always@(negedge sck or negedge rst_n) //Sending Data
begin
   if(!rst_n) begin
      storage       <= 8'h00;
   end
   else if(spi_send) begin
      if(data_out_valid) begin
         storage[0] <= data_byte_out[7];        // receive a data byte 
         storage[1] <= data_byte_out[6];                                  
         storage[2] <= data_byte_out[5];                                  
         storage[3] <= data_byte_out[4];                                  
         storage[4] <= data_byte_out[3];                                  
         storage[5] <= data_byte_out[2];         
         storage[6] <= data_byte_out[1];
         storage[7] <= data_byte_out[0];  
      end     
      else begin
          storage    <= storage >> 1;
      end
   end
end

always@(negedge sck or negedge rst_n) 
begin
   if(!rst_n) begin
      data_out <= 8'h00;
   end
   else if (spi_send) begin                      // Send data in SPI mode
      if(data_out_valid)  begin
         data_out<= {6'h00,data_byte_out[7],1'b0};   
      end     
      else begin
         data_out<= storage;                  // shift out bit by bit
      end 
   end
   else if (opi_send) begin                      // Send data in OPI mode
       data_out  <= data_byte_out;
   end
end
endmodule
