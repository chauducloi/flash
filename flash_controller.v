module flash_controller
(
  input            sck,
  input            clkm,
  input            cs,
  input            rst_n,
  input    [127:0] mem_data,
  inout    [7:0]   i_o,
  output           ds,
  output           analog_on,
  output           eq,
  output   [21:0]  mem_addr,
  output   [7:0]   mem_data_in,
  output           en_wr,
  output           erase 
);

  wire     [7:0]   addr_in, op_in, data_in;
  wire             mode;
  wire     [31:0]  addr;
  wire     [7:0]   op;
  wire     [7:0]   data_byte_in;
  wire             data_in_valid;
  wire     [7:0]   data_out;
  wire     [7:0]   sc_data_out;
  wire             sc_out_valid;
  wire             sc_en;
  wire     [7:0]   pre_data1, pre_data2;
  wire             wel;
  wire     [2:0]   P;
  wire     [2:0]   W;
  wire     [7:0]   prot_data_out;
  wire             protect_signal;
  wire     [7:0]   buf_out;
  wire             w_byte1;
  wire             w_byte2;
  wire             r_byte1;
  wire             r_65h;
  wire             spi;
  wire             opi;
  wire             en_wel;
  wire             dis_wel;
  wire             r_sector;
  wire             prot;
  wire             unprot;
  wire             en_opcode;
  wire             en_addr;
  wire             en_rec;
  wire             en_send;
  wire             r_buffer;
  wire             w_buffer;
  wire             buf_out_valid;
  wire             w_71h_1;
  wire             w_71h_2;
  wire             w_71h_3;
  wire             unxp_sck1;
  wire             unxp_sck2;
  wire             finish_opcode;
  wire             finish_4byte; 
  wire             finish_1byte;
  wire             finish_1clk;
  wire             finish_4dumclk;
  wire             finish_5dumclk;
  wire             finish_6dumclk;
  wire             finish_7dumclk;
  wire             finish_8dumclk;
  wire             finish_4dumbyte;
  wire             finish_r65h_dummy;
  wire             finish_3dumclk;                
  wire             addr_eq_15;
  wire             addr_gt_7;
  wire             w_71h;
  wire             rec_1;
  wire             rec_2;
  wire             rec_3;
  wire             rec_1_unxp;
  wire             rec_2_unxp;
  wire             read_mem;
  wire             read_mem_valid;
  wire             r_03h;
  wire             r_0Bh_0Ch;
  wire             first_read;
  wire             reach_lastbyte;
  wire             finish_20bit;
  wire             finish_24bit;
  wire             load_data;
  wire             load_data_0Ch;
  wire    [7:0]    mem_data_out;
  wire             read_storage2;
  wire             load_storage2;
  wire             finish_read_dummy;
  wire             r0bh_big_addr;
  wire             wrap_around_8byte;
  wire             wrap_around_16byte;
  wire             wrap_con_8byte;
  wire             wrap_con_16byte;
  wire             wrap_8byte;
  wire             wrap_con;
  wire             con_8byte1;
  wire             con_8byte2;
  wire             incr_addr;
  wire             en_write_buf;
  wire             en_read_buf;
  wire             program_signal;
  wire             clr_count;
  wire     [4:0]   count;
  wire             save_start_addr;
  wire     [7:0]   wbyte_addr;
  wire             analog_on2;
  wire             analog_on1;
  wire             program_clr;
  wire    [17:0]   addr_16byte;
  wire             erase_set;
  wire             erase_clr;
  wire             erase_signal;
interface_io INTERFACE
              (
               .en_send             (en_send), 
               .cs                  (cs),
               .sck                 (sck),
               .data_out            (data_out),
               .ds                  (ds),      //output
               .op_in               (op_in), 
               .addr_in             (addr_in),
               .data_in             (data_in),
               .i_o                 (i_o)
              );                    
opcode    OPCODE                  
              (                     
               .sck                 (sck),
               .mode                (mode),
               .rst_n               (rst_n),
               .op_in               (op_in), 
               .en_opcode           (en_opcode),  
               .op                  (op)      // output
              );                  
address    ADDRESS
              (
               .sck                 (sck),
               .clkm                (clkm),
               .rst_n               (rst_n),
               .en_addr             (en_addr),
               .mode                (mode),
               .addr_in             (addr_in),
               .en_write_buf        (en_write_buf),
               .en_read_buf         (en_read_buf),
               .en_wr               (en_wr),
               .save_start_addr     (save_start_addr),
               .program_clr         (program_clr),
               .addr                (addr),    // output 
               .wbyte_addr          (wbyte_addr)
              );
i_o_buffer IO_BUFFER
              (
               .sck                 (sck),
               .rst_n               (rst_n),
               .mode                (mode),
               .data_in             (data_in),
               .read_mem            (read_mem),
               .read_mem_valid      (read_mem_valid),
               .mem_data_out        (mem_data_out),
               .sc_data_out         (sc_data_out),
               .sc_out_valid        (sc_out_valid),
               .sc_en               (sc_en),
               .prot_data_out       (prot_data_out),
               .buf_out             (buf_out),
               .buf_out_valid       (buf_out_valid),
               .r_buffer            (r_buffer),  
               .r_sector            (r_sector),  
               .en_rec              (en_rec),
               .en_send             (en_send),
               .data_out            (data_out),    // Output
               .data_byte_in        (data_byte_in)
               );

pre_sc_reg   PRE_SC_REGISTERS
              (
               .sck                 (sck),
               .rst_n               (rst_n),
               .data_byte_in        (data_byte_in),
               .data_in_valid       (data_in_valid),
               .pre_data1           (pre_data1),  // Output
               .pre_data2           (pre_data2)
              );                  
counter     COUNTER             
              (                  
               .sck                 (sck),
               .cs                  (cs),
               .clr_count           (clr_count),
               .count               (count) 
              );
comb_block   COMBINATION 
              (
               .rst_n               (rst_n),
               .count               (count),                 
               .w_71h_1             (w_71h_1),
               .w_71h_2             (w_71h_2),
               .w_71h_3             (w_71h_3),
               .unxp_sck1           (unxp_sck1),
               .unxp_sck2           (unxp_sck2),
               .mode                (mode),
               .en_rec              (en_rec),
               .r_byte1             (r_byte1),
               .r_65h_1             (r_65h_1),  
               .r_65h_2             (r_65h_2),  
               .r_65h_3             (r_65h_3),
               .r_sector            (r_sector),
               .read_mem            (read_mem), 
               .P                   (P),
               .W                   (W), 
               .addr                (addr),
               .wbyte_addr          (wbyte_addr),
               .analog_on1          (analog_on1),
               .analog_on2          (analog_on2),
               .w_buffer            (w_buffer) ,
               .r_buffer            (r_buffer) ,
               .buf_out_valid       (buf_out_valid),
               .erase_set           (erase_set),
               .erase_clr           (erase_clr),
               .program_set         (program_set),
               .program_clr         (program_clr),
               .addr_16byte         (addr_16byte),
               .r_03h               (r_03h),
               .r_0Bh_0Ch           (r_0Bh_0Ch),
               .erase_signal        (erase_signal),
               .program_signal      (program_signal),
               .en_write_buf        (en_write_buf),
               .en_read_buf         (en_read_buf),
               .analog_on           (analog_on),
               .mem_addr            (mem_addr),
               .finish_opcode       (finish_opcode),
               .finish_4byte        (finish_4byte), 
               .finish_1byte        (finish_1byte),
               .finish_1clk         (finish_1clk),
               .finish_4dumclk      (finish_4dumclk),
               .finish_5dumclk      (finish_5dumclk),
               .finish_6dumclk      (finish_6dumclk),
               .finish_7dumclk      (finish_7dumclk),
               .finish_8dumclk      (finish_8dumclk),
               .finish_4dumbyte     (finish_4dumbyte),
               .finish_read_dummy   (finish_read_dummy),
               .r0bh_big_addr       (r0bh_big_addr),          
               .finish_r65h_dummy   (finish_r65h_dummy),
               .finish_20bit        (finish_20bit),
               .finish_24bit        (finish_24bit),
               .mode_8dumclk        (mode_8dumclk),               
               .mode_10dumclk       (mode_10dumclk),               
               .mode_12dumclk       (mode_12dumclk),               
               .mode_14dumclk       (mode_14dumclk),               
               .mode_16dumclk       (mode_16dumclk),               
               .addr_eq_15          (addr_eq_15),                           
               .addr_gt_7           (addr_gt_7),                           
               .wrap_around_8byte   (wrap_around_8byte),
               .wrap_around_16byte  (wrap_around_16byte),
               .wrap_con_8byte      (wrap_con_8byte),
               .wrap_con_16byte     (wrap_con_16byte),
               .w_71h               (w_71h),
               .rec_1               (rec_1),
               .rec_2               (rec_2),
               .rec_3               (rec_3),
               .rec_1_unxp          (rec_1_unxp),
               .rec_2_unxp          (rec_2_unxp), 
               .en_send             (en_send),
               .load_data_0Ch       (load_data_0Ch),
               .data_in_valid       (data_in_valid)         
                 );
fsm2          FSM2
              ( 
               .clkm                (clkm),
               .program_signal      (program_signal),
               .erase_signal        (erase_signal),
               .cs                  (cs),
               .en_wr               (en_wr),
               .erase               (erase),
               .erase_clr           (erase_clr),
               .analog_on2          (analog_on2)
              );
fsm           FSM  
              (
               .wel                 (wel),
               .mode                (mode),
               .sck                 (sck),
               .cs                  (cs),
               .op                  (op), 
               .finish_opcode       (finish_opcode),                  
               .finish_4byte        (finish_4byte), 
               .finish_1byte        (finish_1byte),
               .finish_1clk         (finish_1clk),
               .finish_4dumclk      (finish_4dumclk),
               .finish_5dumclk      (finish_5dumclk),
               .finish_6dumclk      (finish_6dumclk),
               .finish_7dumclk      (finish_7dumclk),
               .finish_8dumclk      (finish_8dumclk),
               .finish_4dumbyte     (finish_4dumbyte),
               .finish_r65h_dummy   (finish_r65h_dummy),
               .finish_read_dummy   (finish_read_dummy),
               .finish_20bit        (finish_20bit),
               .finish_24bit        (finish_24bit),
               .mode_8dumclk        (mode_8dumclk),               
               .mode_10dumclk       (mode_10dumclk),               
               .mode_12dumclk       (mode_12dumclk),               
               .mode_14dumclk       (mode_14dumclk),               
               .mode_16dumclk       (mode_16dumclk),     
               .r0bh_big_addr       (r0bh_big_addr),          
               .addr_eq_15          (addr_eq_15),                           
               .addr_gt_7           (addr_gt_7),                           
               .load_data           (load_data),
               .load_data_0Ch       (load_data_0Ch),
               .reach_lastbyte      (reach_lastbyte),
               .wrap_around_8byte   (wrap_around_8byte),
               .wrap_around_16byte  (wrap_around_16byte),
               .wrap_con_8byte      (wrap_con_8byte),
               .wrap_con_16byte     (wrap_con_16byte),
               .program_signal      (program_signal),
               .protect_signal      (protect_signal),
               .erase_set           (erase_set),
               .save_start_addr     (save_start_addr),
               .program_set         (program_set),
               .wrap_8byte          (wrap_8byte),
               .wrap_con            (wrap_con),
               .con_8byte1          (con_8byte1),
               .con_8byte2          (con_8byte2),
               .incr_addr           (incr_addr),
               .analog_on1          (analog_on1),
               .eq                  (eq),
               .first_read          (first_read),
               .read_mem            (read_mem),
               .read_mem_valid      (read_mem_valid),
               .r_03h               (r_03h),                      
               .r_0Bh_0Ch           (r_0Bh_0Ch),                      
               .load_storage2       (load_storage2),
               .read_storage2       (read_storage2), 
               //outputs           
               .w_byte1             (w_byte1), 
               .w_byte2             (w_byte2),
               .w_71h_1             (w_71h_1),   
               .w_71h_2             (w_71h_2),   
               .w_71h_3             (w_71h_3),   
               .unxp_sck1           (unxp_sck1), 
               .unxp_sck2           (unxp_sck2), 
               .r_byte1             (r_byte1), 
               .r_65h_1             (r_65h_1),   
               .r_65h_2             (r_65h_2),   
               .r_65h_3             (r_65h_3),
               .sc_out_valid        (sc_out_valid),
               .r_buffer            (r_buffer),
               .buf_out_valid       (buf_out_valid),
               .w_buffer            (w_buffer),
               .spi                 (spi),
               .opi                 (opi),    
               .en_wel              (en_wel),    
               .dis_wel             (dis_wel),
               .r_sector            (r_sector),
               .prot                (prot),
               .unprot              (unprot),
               .en_opcode           (en_opcode),
               .en_addr             (en_addr),
               .en_rec              (en_rec),
               .clr_count           (clr_count)     
              );
sc_reg      STATUS_CONTROL
              (
               .sck                 (sck),
               .rst_n               (rst_n),
               .cs                  (cs),
               .addr                (addr),
               .data_byte_in        (data_byte_in),
               .pre_data1           (pre_data1),
               .pre_data2           (pre_data2),
               .w_byte1             (w_byte1), 
               .w_byte2             (w_byte2), 
               .w_71h               (w_71h),   
               .rec_1               (rec_1),   
               .rec_2               (rec_2),   
               .rec_3               (rec_3),   
               .rec_1_unxp          (rec_1_unxp),   
               .rec_2_unxp          (rec_2_unxp),
               .r_byte1             (r_byte1), 
               .r_65h_1             (r_65h_1),   
               .r_65h_2             (r_65h_2),   
               .r_65h_3             (r_65h_3),   
               .spi                 (spi),
               .opi                 (opi),
               .en_wel              (en_wel),     
               .dis_wel             (dis_wel),    
               .P                   (P),
               .W                   (W), 
               .sc_en               (sc_en),
               .sc_data_out         (sc_data_out),
               .wel                 (wel),
               .mode                (mode)
              );
sector_protection SECTOR_PROTECTION
               (
               .cs                  (cs),
               .rst_n               (rst_n),
               .addr                (addr),
               .prot                (prot),
               .unprot              (unprot),
               .r_sector            (r_sector),
               .prot_data_out       (prot_data_out),
               .protect_signal      (protect_signal)
               );               
data_buffer       DATA_BUFFER   
               (                
               .sck                 (sck),
               .rst_n               (rst_n),
               .addr                (addr),
               .wbyte_addr          (wbyte_addr),
               .data_byte_in        (data_byte_in),
               .en_write_buf        (en_write_buf),
               .en_read_buf         (en_read_buf),
               .en_wr               (en_wr),
               .buf_out             (buf_out),
               .mem_data_in         (mem_data_in)
               );               
read_memory      READ_MEMORY 
              (                
               .sck                 (sck),
               .rst_n               (rst_n),
               .mode                (mode), 
               .r_03h               (r_03h),
               .r_0Bh_0Ch           (r_0Bh_0Ch),
               .wrap_8byte          (wrap_8byte),
               .wrap_con            (wrap_con),
               .con_8byte1          (con_8byte1),
               .con_8byte2          (con_8byte2),
               .read_mem_valid      (read_mem_valid),
               .first_read          (first_read),
               .read_mem            (read_mem),
               .addr                (addr),
               .mem_data            (mem_data),
               .mode_8dumclk        (mode_8dumclk),               
               .mode_10dumclk       (mode_10dumclk),               
               .mode_12dumclk       (mode_12dumclk),               
               .mode_14dumclk       (mode_14dumclk),               
               .mode_16dumclk       (mode_16dumclk),               
               .read_storage2       (read_storage2), 
               .load_storage2       (load_storage2),
               .analog_on1          (analog_on1),
               .incr_addr           (incr_addr),
               .load_data           (load_data),
               .reach_lastbyte      (reach_lastbyte),
               .addr_16byte         (addr_16byte),
               .mem_data_out        (mem_data_out)
              );
endmodule              
