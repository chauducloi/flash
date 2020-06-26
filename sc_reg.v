module sc_reg
 (
  // Input
  input                 sck,
  input                 rst_n,
  input                 cs,
  input        [31:0]   addr,
  input        [7:0]    data_byte_in,
  input        [7:0]    pre_data1,
  input        [7:0]    pre_data2,
  input                 w_byte1, 
  input                 w_byte2, 
  input                 w_71h,
  input                 rec_1,
  input                 rec_2,
  input                 rec_3,
  input                 rec_1_unxp,
  input                 rec_2_unxp,
  input                 r_byte1, 
  input                 r_65h_1,   
  input                 r_65h_2,   
  input                 r_65h_3,   
  input                 spi,
  input                 opi,
  input                 en_wel,     
  input                 dis_wel,    
  // Output
  output        [2:0]   P,
  output        [2:0]   W,
  output                sc_en,
  output   reg  [7:0]   sc_data_out,
  output                wel,
  output                mode
 );

// Reg & wire
reg        [7:0]      byte1, byte2, byte3;
wire       [7:0]      sc_addr;

assign  sc_addr     =  addr[7:0];
assign  sc_en       =  r_byte1 || r_65h_1 || r_65h_2 || r_65h_3; 
assign  wel         =  byte1[1];
assign  mode        =  byte2[3];
assign  P           =  byte3[3:0];
assign  W           =  byte3[7:5];

//---- Status Control Register Byte 1----//  
always@(posedge cs or negedge rst_n) 
begin 
   if(!rst_n) begin 
      byte1    <=  8'b00;
   end 
   else if(en_wel) begin                                         // Write Enable
      byte1[1] <= 1'b1;
   end
   else if(dis_wel) begin                                        // Write Disable 
      byte1[1] <= 1'b0;
   end
   else if(spi) begin                                           //Enter OPI
      byte1[1] <= 1'b0;
   end 
   else if(opi) begin                                           // Return to SPI mode 
      byte1[1] <= 1'b0;
   end  
   else if (w_byte1) begin                                     // Write Data To Byte 1 
      byte1    <= {data_byte_in[7:2],1'b0,data_byte_in[0]};   
   end
   else if (w_byte2) begin                                    // Write Data To Byte 2
     byte1[1]  <= 1'b0; 
   end
   else if(w_71h) begin                                   // Write 71H
      case(sc_addr)
         8'h00:begin
                  if(rec_1)      byte1 <= {data_byte_in[7:2],1'b0, data_byte_in[0]};
                  if(rec_1_unxp) byte1 <= {pre_data1[7:2],1'b0, pre_data1[0]};     
                  if(rec_2)      byte1 <= {pre_data1[7:2],1'b0, pre_data1[0]};    
                  if(rec_2_unxp) byte1 <= {pre_data2[7:2],1'b0, pre_data2[0]};    
                  if(rec_3)      byte1 <= {pre_data2[7:2],1'b0, pre_data2[0]};    
               end            
         default: begin
                     byte1 <= {byte1[7:2],1'b0,byte1[0]};
                  end 
      endcase
   end
end

//----- Status Control Registers Byte 2 --------//

always@(posedge cs or negedge rst_n) 
begin 
   if(!rst_n) begin 
      byte2    <=  8'h00;
   end 
   else if(spi) begin                          //Enter OPI mode
      byte2[3] <=   1'b0;
   end
   else if(opi) begin                          //Return to SPI mode
      byte2[3] <=   1'b1;
   end
   else if (w_byte2) begin                     // Write Data To Byte 2
      byte2    <= data_byte_in; 
   end
   else if(w_71h)begin                         // Write 71h 
      case(sc_addr)
         8'h00: begin
                   if(rec_2)       byte2 <= data_byte_in; 
                   if(rec_2_unxp)  byte2 <= pre_data1;    
                   if(rec_3)       byte2 <= pre_data1;    
                end           
         8'h01: begin 
                   if(rec_1)       byte2 <= data_byte_in; 
                   if(rec_1_unxp)  byte2 <= pre_data1;     
                   if(rec_2)       byte2 <= pre_data1;    
              	   if(rec_2_unxp)  byte2 <= pre_data2;    
                   if(rec_3)       byte2 <= pre_data2;    
                end  
      endcase
   end
end

//----- Status Control Registers Byte 3 -------//

always@(posedge cs or negedge rst_n) 
begin
   if(!rst_n) begin
      byte3  <= 8'h00;
   end
   else if (w_71h) begin                              // write 71h
      case(sc_addr)
         8'h00:begin
                  if(rec_3)       byte3 <= data_byte_in;
               end
         8'h01:begin
                  if(rec_2)       byte3 <= data_byte_in;
                  if(rec_2_unxp)  byte3 <= pre_data1;
                  if(rec_3)       byte3 <= pre_data1;    
               end 
         8'h02:begin
                  if(rec_1)       byte3 <= data_byte_in;
                  if(rec_1_unxp)  byte3 <= pre_data1;    
                  if(rec_2)       byte3 <= pre_data1;   
                  if(rec_2_unxp)  byte3 <= pre_data2;    
               end  
      endcase
   end
end

//------  Read 65h -------//

always@(*) 
begin
   if(r_byte1) begin 
      sc_data_out  =  byte1;
   end
   else begin
      sc_data_out    = 8'h00;
      case(sc_addr) 
         8'h00:begin
                  if      (r_65h_1)  sc_data_out  = byte1;
                  else if (r_65h_2)  sc_data_out  = byte2;
                  else if (r_65h_3)  sc_data_out  = byte3;
               end
         8'h01:begin
                  if      (r_65h_1)  sc_data_out  = byte2;
                  else if (r_65h_2 || r_65h_3) 
                                     sc_data_out  = byte3;
               end   
         8'h02:begin
                  if(r_65h_1 || r_65h_2 || r_65h_3)
                                     sc_data_out  = byte3;
               end
      endcase
   end
end
endmodule
