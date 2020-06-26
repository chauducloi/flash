module comb_block
 (
  input              rst_n,
  input      [4:0]   count,
  input              w_71h_1,
  input              w_71h_2,
  input              w_71h_3,
  input              unxp_sck1,
  input              unxp_sck2,
  input              mode,
  input              en_rec,
  input              r_byte1, 
  input              r_65h_1,   
  input              r_65h_2,   
  input              r_65h_3,
  input              r_sector,
  input              read_mem,
  input      [2:0]   P,
  input      [2:0]   W,
  input      [31:0]  addr,
////
  input      [7:0]   wbyte_addr,
  input              analog_on1,
  input              analog_on2,
  input              w_buffer,
  input              r_buffer,
  input              buf_out_valid,
  input              erase_set,
  input              erase_clr,
  input              program_set,
  input              program_clr,
  input       [17:0] addr_16byte,
  input              r_03h,
  input              r_0Bh_0Ch,
  output  reg        erase_signal,
  output  reg        program_signal,
  output             en_write_buf,
  output             en_read_buf,
  output             analog_on,
  output  reg [21:0] mem_addr,
// 
  output             finish_opcode,
  output             finish_4byte, 
  output             finish_1byte,
  output             finish_1clk,
  output             finish_4dumclk,
  output             finish_5dumclk,
  output             finish_6dumclk,
  output             finish_7dumclk,
  output             finish_8dumclk,
  output             finish_4dumbyte,
  output             finish_read_dummy,
  output             r0bh_big_addr,
  output             finish_r65h_dummy,
  output             finish_20bit,
  output             finish_24bit,
  output             mode_8dumclk,
  output             mode_10dumclk,
  output             mode_12dumclk,
  output             mode_14dumclk,
  output             mode_16dumclk,
  output             addr_eq_15,
  output             addr_gt_7,
  output             wrap_around_8byte,
  output             wrap_around_16byte,
  output             wrap_con_8byte,
  output             wrap_con_16byte,
  output             w_71h,
  output             rec_1,
  output             rec_2,
  output             rec_3,
  output             rec_1_unxp,
  output             rec_2_unxp, 
  output             en_send,
  output             data_in_valid,
  output             load_data_0Ch
 );
//Read 0BH OPI
assign addr_gt_12  = (addr[3:0] == 4'd12)||(addr[3:0] == 4'd13)||(addr[3:0] == 4'd14)||(addr[3:0] == 4'd15);
assign addr_gt_11  = (addr_gt_12||(addr[3:0]==4'd11));
assign addr_gt_10  = (addr_gt_11||(addr[3:0]==4'd10));
assign addr_gt_9   = (addr_gt_10||(addr[3:0]==4'd9));
assign addr_eq_15  = (addr[3:0] == 4'd15);

assign mode_8dumclk       = (P==3'b000);
assign mode_10dumclk      = (P==3'b001);
assign mode_12dumclk      = (P==3'b010);
assign mode_14dumclk      = (P==3'b011);
assign mode_16dumclk      = (P==3'b100);

//Read with wrap
assign wrap_around_8byte  = (W==3'b000);
assign wrap_around_16byte = (W==3'b001);
assign wrap_con_8byte     = (W==3'b100);
assign wrap_con_16byte    = (W==3'b101);
assign addr_gt_7          = addr[3];

assign finish_20bit       = ( count == 5'd19);
assign finish_24bit       = ( count == 5'd23);
assign finish_opcode      = ((count == 5'd1) && mode || (count == 5'd8)  && !mode);
assign finish_4byte       = ((count == 5'd3) && mode || (count == 5'd31) && !mode); 
assign finish_1byte       = ((count == 5'd0) && mode || (count == 5'd7)  && !mode); 
assign finish_8dumclk     = ( count == 5'd7);
assign finish_10dumclk    = ( count == 5'd9);
assign finish_12dumclk    = ( count == 5'd11);
assign finish_14dumclk    = ( count == 5'd13);
assign finish_16dumclk    = ( count == 5'd15);
assign finish_4dumbyte    = ( count == 5'd3);
assign finish_1clk        =  count == 5'd0;
assign finish_4dumclk     =  finish_4dumbyte;
assign finish_5dumclk     =  count == 5'd4;
assign finish_6dumclk     =  count == 5'd5;
assign finish_7dumclk     =  count == 5'd6;

assign load_data_0Ch     = (wrap_con_16byte || (wrap_con_8byte&&!addr_gt_7))&&(
                           ((count == 4'd11) &&  mode_8dumclk )||
                           ((count == 4'd10) &&  mode_10dumclk)||
                           ((count == 4'd9)  &&  mode_12dumclk)||
                           ((count == 4'd8)  &&  mode_14dumclk)||
                           ((count == 4'd8)  &&  mode_16dumclk))||
                          wrap_con_8byte&&addr_gt_7&&(
                           ((count == 4'd3) &&  mode_8dumclk )||
                           ((count == 4'd2) &&  mode_10dumclk)||
                           ((count == 4'd1) &&  mode_12dumclk)||
                           ((count == 4'd0) &&  mode_14dumclk)||
                           ((count == 4'd0) &&  mode_16dumclk));
                           
assign finish_r65h_dummy  = (finish_4dumbyte&&mode||finish_8dumclk&&!mode); 
assign finish_read_dummy  = mode_8dumclk&&finish_8dumclk  || mode_10dumclk&&finish_10dumclk ||
                            mode_12dumclk&&finish_12dumclk|| mode_14dumclk&&finish_14dumclk ||
                            mode_16dumclk&&finish_16dumclk;  
assign r0bh_big_addr      = mode_8dumclk&&addr_gt_12   || mode_10dumclk&&addr_gt_11 ||
                            mode_12dumclk&&addr_gt_10  || mode_14dumclk&&addr_gt_9  ||
                            mode_16dumclk&&addr_gt_9;

assign en_send            = r_byte1 || r_65h_1 || r_65h_2 || r_65h_3  || r_sector || r_buffer || read_mem;  
assign data_in_valid      = en_rec&&((count == 5'd7)&&!mode || mode);                          

// The signals to control the Write 71h Command
assign  w_71h      =  w_71h_1 ||  w_71h_2 ||  w_71h_3;
assign  rec_1      =  w_71h_1 && !unxp_sck1;
assign  rec_2      =  w_71h_2 && !unxp_sck2;
assign  rec_3      =  w_71h_3; 
assign  rec_1_unxp =  w_71h_1 &&  unxp_sck1;
assign  rec_2_unxp =  w_71h_2 &&  unxp_sck2;
// buffer
assign en_write_buf = w_buffer && data_in_valid;
assign en_read_buf  = r_buffer && buf_out_valid;

// memory model
assign analog_on = analog_on1 | analog_on2;
// memory address
always@(*) 
begin
   if(r_03h)
      mem_addr = {addr[17:0],4'b0};
   else if (r_0Bh_0Ch) 
      mem_addr = {addr[21:4],4'b0};
   else if (program_signal)
      mem_addr = {addr[21:8],wbyte_addr[7:0]};
   else if (erase_signal)
      mem_addr = addr[21:0];
   else 
      mem_addr = {addr_16byte,4'h0};
end 
// program latch
always@(*)
begin
   if(program_set)
      program_signal = 1'b1;
   else if(program_clr || !rst_n)
      program_signal = 1'b0;
end
always@(*)
begin
   if(erase_set)
      erase_signal = 1'b1;
   else if(erase_clr || !rst_n)
      erase_signal = 1'b0;
end

endmodule
