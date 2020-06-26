module top_flash_controller
 ( 
   input          sck,
   input          rst_n,
   input          cs,
   inout   [7:0]  i_o,
   output         ds
 );
wire           clkm;
wire           analog_on;
wire           eq;
wire   [21:0]  mem_addr;
wire   [7:0]   mem_data_in;
wire           en_wr;
wire           erase;
wire   [127:0] mem_data;

memory_model  MM (
                  .analog_on    (analog_on),
                  .eq           (eq),
                  .en_wr        (en_wr),
                  .erase        (erase),
                  .mem_addr     (mem_addr),
                  .sck          (sck),
                  .mem_data_in  (mem_data_in),
                  .clkm         (clkm),
                  .mem_data     (mem_data)
                 );
flash_controller FC (
                  .sck          (sck),
                  .clkm         (clkm),
                  .cs           (cs),
                  .rst_n        (rst_n),
                  .mem_data     (mem_data),
                  .i_o          (i_o),
                  .ds           (ds),
                  .analog_on    (analog_on),
                  .eq           (eq),
                  .mem_addr     (mem_addr),
                  .mem_data_in  (mem_data_in),
                  .en_wr        (en_wr),
                  .erase        (erase)
                  );
endmodule
