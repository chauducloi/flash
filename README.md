module read_memory
 (
  input                  sck,
  input                  rst_n,
  input                  mode,
  input                  r_03h,
  input                  r_0Bh_0Ch,
  input                  read_mem_valid,
  input                  first_read,
  input                  read_mem,
  input        [31:0]    addr,
  input        [127:0]   mem_data,     // Data from Memory
  input                  wrap_8byte,  
  input                  wrap_con,  
  input                  con_8byte1,
  input                  con_8byte2, 
  input                  mode_8dumclk,
  input                  mode_10dumclk,
  input                  mode_12dumclk,
  input                  mode_14dumclk,
  input                  mode_16dumclk,
  input                  read_storage2,
  input                  load_storage2, 
  input                  analog_on1,
  input                  incr_addr,
  output   reg           load_data,
  output                 reach_lastbyte,
  output   reg   [17:0]  addr_16byte,
  output   reg   [7:0]   mem_data_out  // Data output to i_o_buffer     
 );

integer       i;
wire  [3:0]   firstbyte_addr;
wire  [3:0]   lastbyte_addr;
reg   [7:0]   storage [0:15];
reg   [7:0]   storage2[9:15];  
reg   [3:0]   byte_addr;

assign lastbyte_addr  = wrap_8byte&!addr[3]?4'd7: //wrap around 8 bytes & start address < 8
                        wrap_8byte&addr[3]? 4'd15: //wrap around 8 bytes & start address > 8
                        wrap_con?           (addr[3:0]==8? 15:addr[3:0]-4'd1): //wrap continuous 16 bytes
                        con_8byte1?         4'd7:   // wrap continous 8 bytes
                                            4'd15;
assign firstbyte_addr = wrap_8byte&!addr[3]?4'd0: //wrap around 8 bytes & start address < 8
                        wrap_8byte&addr[3]? 4'd8: //wrap around 8 bytes & start address > 8
                        con_8byte2?         4'd8: // wrap continuous 8 bytes   
                                            4'd0;

assign en_read          =  !mode&&read_mem&&read_mem_valid || mode&&read_mem;
assign reach_lastbyte   = (byte_addr == lastbyte_addr || addr[3:0]==15&&first_read);
assign next_16byte_addr = !mode && byte_addr == 4'd15 ||
                           mode&&!wrap_con&&(
                           ((byte_addr == 12) &&  mode_8dumclk )||
                           ((byte_addr == 11) &&  mode_10dumclk)||
                           ((byte_addr == 10) &&  mode_12dumclk)||
                           ((byte_addr == 9)  &&  mode_14dumclk)||
                           ((byte_addr == 9)  &&  mode_16dumclk));

always@(posedge sck or negedge rst_n) // STORAGE1
begin 
   if(!rst_n) begin
      for(i=0;i<=15;i=i+1) begin
         storage[i] <= 8'h00;
      end
   end
   else if(analog_on1) begin
      storage[0]   <=   mem_data[7:0];
      storage[1]   <=   mem_data[15:8];
      storage[2]   <=   mem_data[23:16];
      storage[3]   <=   mem_data[31:24];
      storage[4]   <=   mem_data[39:32];
      storage[5]   <=   mem_data[47:40];
      storage[6]   <=   mem_data[55:48];
      storage[7]   <=   mem_data[63:56];
      storage[8]   <=   mem_data[71:64];
      storage[9]   <=   mem_data[79:72];
      storage[10]  <=   mem_data[87:80];
      storage[11]  <=   mem_data[95:88];
      storage[12]  <=   mem_data[103:96];
      storage[13]  <=   mem_data[111:104];
      storage[14]  <=   mem_data[119:112];
      storage[15]  <=   mem_data[127:120];
   end 
end

always@(posedge sck or negedge rst_n)   // STORAGE2
begin 
   if(!rst_n) begin
      for(i=9;i<=15;i=i+1) begin
         storage2[i] <= 8'h00;
      end
   end
   else if(analog_on1 && load_storage2) begin
      storage2[9]   <=   storage[9]; 
      storage2[10]  <=   storage[10];
      storage2[11]  <=   storage[11];
      storage2[12]  <=   storage[12];
      storage2[13]  <=   storage[13];
      storage2[14]  <=   storage[14];
      storage2[15]  <=   storage[15];
   end 
end

always@(posedge sck or negedge rst_n) //The address of 16-byte data packet 
begin
   if(!rst_n)     begin 
      addr_16byte <=  18'd0;
   end  
   else if(r_03h) begin               // Read 03h  
      addr_16byte <=  addr[17:0];
   end
   else if(r_0Bh_0Ch) begin               // Read 0Bh
      addr_16byte <=  addr[21:4];
   end
   else if(load_storage2) begin 
      addr_16byte <=  addr[21:4] + 18'd1;
   end    
   else if(en_read) begin 
      if(first_read && !read_storage2) begin  // The first time 16-byte memory addr has been readed
         addr_16byte <= addr[21:4]; 
      end
      else begin 
         addr_16byte <= next_16byte_addr||incr_addr?addr_16byte+18'd1:addr_16byte;   
      end
   end
end

always@(posedge sck or negedge rst_n) //The address of each databyte in 16-byte data packet 
begin
   if(!rst_n) begin 
      byte_addr  <=  4'h0;
   end  
   else if(en_read) begin 
      if(first_read) begin
         byte_addr <=  addr[3:0] + 4'd1;
      end
      else begin
         if(con_8byte1) begin       // wrap continuous 8 bytes mode, start address < 7
            byte_addr <=  reach_lastbyte? 4'd8:
                          (byte_addr == 4'd7)? 4'd0: byte_addr + 4'd1;
         end
         else if(con_8byte2) begin // wrap continuous 8 bytes mode, start address > 7
            byte_addr <=  reach_lastbyte?      4'd0:
                          byte_addr == 4'd15? 4'd8 : byte_addr + 4'd1;
         end
         else begin
            byte_addr <=  reach_lastbyte? firstbyte_addr : byte_addr + 4'd1;
         end
      end
   end
end

always@(*)     //  OUTPUT: mem_data_out
begin 
   if(en_read) begin   
      if(first_read) begin 
         mem_data_out = read_storage2? storage2[addr[3:0]] : storage[addr[3:0]];
      end
      else begin
         mem_data_out = read_storage2? storage2[byte_addr] : storage[byte_addr];
      end
   end
   else begin
      mem_data_out = 8'h0;
   end  
end 

always@(posedge sck)
begin
   if(!rst_n) 
      load_data <= 1'b0;
   else 
      load_data <= next_16byte_addr;
end

endmodule
