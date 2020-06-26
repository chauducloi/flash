`timescale 100ps/10ps

module memory_model 
  (
    input                      analog_on,
    input                      eq,
    input                      en_wr,
    input                      erase,
    input          [21:0]      mem_addr,
    input                      sck,
    input          [7:0]       mem_data_in,
    output   reg               clkm,
    output   reg   [127:0]     mem_data
  );

reg   [127:0]    storage;
reg   [7:0]      mem [0:16383][0:255];
wire  [13:0]     page_addr; 
wire  [3:0]      byte16_addr;
wire  [7:0]      byte_addr;

initial 
begin
   clkm = 0;
   forever #25 clkm = ~clkm;
end

assign page_addr   = mem_addr[21:8];
assign byte16_addr = mem_addr[7:4];
assign byte_addr   = mem_addr[7:0];  
assign block_addr  = mem_addr[21:12];
integer i,j;
initial begin 
   mem_data = 0;
   storage  = 0;
   for (i = 0; i<= 16383; i = i+1) begin
       for(j=0; j<=255; j = j+1) begin
           mem[i][j] = 8'hFF;
       end
   end  
end

always @(posedge eq) // Read memory
begin
   if (analog_on) begin
      #100    storage[7:0]     = mem[page_addr][{byte16_addr,4'h0}]; 
              storage[15:8]    = mem[page_addr][{byte16_addr,4'h1}]; 
              storage[23:16]   = mem[page_addr][{byte16_addr,4'h2}]; 
              storage[31:24]   = mem[page_addr][{byte16_addr,4'h3}]; 
              storage[39:32]   = mem[page_addr][{byte16_addr,4'h4}]; 
              storage[47:40]   = mem[page_addr][{byte16_addr,4'h5}]; 
              storage[55:48]   = mem[page_addr][{byte16_addr,4'h6}]; 
              storage[63:56]   = mem[page_addr][{byte16_addr,4'h7}]; 
              storage[71:64]   = mem[page_addr][{byte16_addr,4'h8}]; 
              storage[79:72]   = mem[page_addr][{byte16_addr,4'h9}]; 
              storage[87:80]   = mem[page_addr][{byte16_addr,4'ha}]; 
              storage[95:88]   = mem[page_addr][{byte16_addr,4'hb}]; 
              storage[103:96]  = mem[page_addr][{byte16_addr,4'hc}]; 
              storage[111:104] = mem[page_addr][{byte16_addr,4'hd}]; 
              storage[119:112] = mem[page_addr][{byte16_addr,4'he}]; 
              storage[127:120] = mem[page_addr][{byte16_addr,4'hf}]; 
      #350    mem_data  = storage;
   end
   else begin
      mem_data = 0;
   end
end 

always @(*) begin
   if(en_wr && analog_on) begin 
      mem[page_addr][byte_addr] = mem_data_in;
   end
end
always @(*) begin 
   if(erase && analog_on) begin
       for (i=0; i<=255;i=i+1) begin
          mem[{block_addr,4'h0}][i] = 8'hFF;
          mem[{block_addr,4'h1}][i] = 8'hFF;
          mem[{block_addr,4'h2}][i] = 8'hFF;
          mem[{block_addr,4'h3}][i] = 8'hFF;
          mem[{block_addr,4'h4}][i] = 8'hFF;
          mem[{block_addr,4'h5}][i] = 8'hFF;
          mem[{block_addr,4'h6}][i] = 8'hFF;
          mem[{block_addr,4'h7}][i] = 8'hFF;
          mem[{block_addr,4'h8}][i] = 8'hFF;
          mem[{block_addr,4'h9}][i] = 8'hFF;
          mem[{block_addr,4'ha}][i] = 8'hFF;
          mem[{block_addr,4'hb}][i] = 8'hFF;
          mem[{block_addr,4'hc}][i] = 8'hFF;
          mem[{block_addr,4'hd}][i] = 8'hFF;
          mem[{block_addr,4'he}][i] = 8'hFF;
          mem[{block_addr,4'hf}][i] = 8'hFF;
      end 
   end
end 
endmodule 
