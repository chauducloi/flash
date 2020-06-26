module pre_sc_reg
 (
 // Inputs
  input                       sck,
  input                       rst_n,
  input             [7:0]     data_byte_in,
  input                       data_in_valid,
 // Outputs 
  output    reg     [7:0]     pre_data1,
  output    reg     [7:0]     pre_data2
 );


// Store the first 3 bytes data_byte_in
always@(posedge sck or negedge rst_n) 
begin
   if(!rst_n) begin
      pre_data1 <= 8'h00;
   end
   else if(data_in_valid) begin                                 
      pre_data1 <= data_byte_in;       
   end
end

always@(posedge sck or negedge rst_n) 
begin
   if(!rst_n) begin
      pre_data2 <= 8'h00;
   end
   else if(data_in_valid) begin                                  
      pre_data2 <= pre_data1;
   end
end
endmodule   

