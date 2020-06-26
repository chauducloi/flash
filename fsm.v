module fsm
(
// Inputs
 input                 wel,
 input                 mode,
 input                 sck,
 input                 cs,
 input         [7:0]   op,

 input                 finish_opcode,
 input                 finish_4byte, 
 input                 finish_1byte,
 input                 finish_1clk,
 input                 finish_4dumclk,
 input                 finish_5dumclk,
 input                 finish_6dumclk,
 input                 finish_7dumclk,
 input                 finish_8dumclk,
 input                 finish_4dumbyte,
 input                 finish_r65h_dummy,
 input                 finish_read_dummy,
 input                 finish_20bit,
 input                 finish_24bit,
 input                 mode_8dumclk,
 input                 mode_10dumclk,
 input                 mode_12dumclk,
 input                 mode_14dumclk,
 input                 mode_16dumclk,
 input                 r0bh_big_addr,
 input                 addr_eq_15,
 input                 addr_gt_7,
 input                 load_data,
 input                 load_data_0Ch,
 input                 reach_lastbyte,
 input                 wrap_around_8byte,
 input                 wrap_around_16byte,
 input                 wrap_con_8byte,
 input                 wrap_con_16byte,
 input                 program_signal,
 input                 protect_signal,
 output   reg          erase_set,
 output   reg          save_start_addr,
 output   reg          program_set,  
 output   reg          wrap_8byte,
 output   reg          wrap_con,
 output   reg          con_8byte1,
 output   reg          con_8byte2,
 output   reg          incr_addr,
 output   reg          analog_on1,
 output   reg          eq,
 output   reg          first_read,
 output   reg          read_mem,
 output   reg          read_mem_valid,
 output   reg          r_03h,
 output   reg          r_0Bh_0Ch,
 output   reg          load_storage2,
 output   reg          read_storage2,
//Outputs
 output   reg          w_byte1, 
 output   reg          w_byte2, 
 output   reg          w_71h_1,
 output   reg          w_71h_2,
 output   reg          w_71h_3,
 output   reg          unxp_sck1,
 output   reg          unxp_sck2,
 output   reg          r_byte1, 
 output   reg          r_65h_1,   
 output   reg          r_65h_2,   
 output   reg          r_65h_3,
 output   reg          sc_out_valid,   
 output   reg          r_buffer,
 output   reg          buf_out_valid,
 output   reg          w_buffer,
 output   reg          spi,
 output   reg          opi,    
 output   reg          en_wel,    
 output   reg          dis_wel,
 output   reg          r_sector,
 output   reg          prot,
 output   reg          unprot,
 output   reg          en_opcode,
 output   reg          en_addr,
 output   reg          en_rec,
 output   reg          clr_count
);
parameter   STATE_REC_OP       = 5'd0, 
            STATE_ADDR         = 5'd1,
            STATE_RECEIVE      = 5'd2,
            STATE_SEND         = 5'd3,
            STATE_DUMMY        = 5'd4,
            STATE_IDLE         = 5'd5,
            STATE_REC_71H_2    = 5'd6,
            STATE_REC_71H_3    = 5'd7,
            STATE_REC_71H_4    = 5'd8,
            STATE_R65H_2       = 5'd9,
            STATE_R65H_3       = 5'd10,
            STATE_WBUFFER      = 5'd11,
            STATE_WBYTE1       = 5'd12,
            STATE_WBYTE2       = 5'd13,
            STATE_R0BH_1       = 5'd14,
            STATE_R0BH_2       = 5'd15,
            STATE_R0BH_3       = 5'd16,
            STATE_R0BH_4       = 5'd17,
            STATE_R0CH_1       = 5'd18,
            STATE_R0CH_2       = 5'd19,
            STATE_R0CH_3       = 5'd20,
            STATE_R0CH_4       = 5'd21;

parameter   CMD_W_DISABLE  = 8'H04,   CMD_W_ENABLE   = 8'H06,
            CMD_R_SECTOR   = 8'H3C,   CMD_R_BYTE1    = 8'H05,
            CMD_R_65H      = 8'H65,   CMD_W_BYTE1    = 8'H01,
            CMD_W_BYTE2    = 8'H31,   CMD_W_71H      = 8'H71,
            CMD_PROTECT    = 8'H36,   CMD_UNPROTECT  = 8'H39,
            CMD_SPI        = 8'HFF,   CMD_OPI        = 8'HE8,
            CMD_R_BUFFER   = 8'HD4,   CMD_W_BUFFER   = 8'H84,
            CMD_R_03H      = 8'H03,   CMD_R_0BH      = 8'H0B,
            CMD_R_0CH      = 8'H0C,   CMD_PROGRAM    = 8'H02,
            CMD_ERASE      = 8'H20;

reg    [4:0]   nstate;              // Next state   
reg    [4:0]   pstate;              // Present State
always@(posedge sck or posedge cs)
begin
   if(cs) 
      pstate  <=  STATE_REC_OP;                     // Reset the states when CS is set to "1" 
   else 
      pstate  <=  nstate;
end
always@(*) 
begin
   nstate        = pstate;
   clr_count     = 1'b0;
   en_opcode     = 1'b0; // Do not allow OPCODE BLOCK to receive opcode
   en_addr       = 1'b0; // Do not allow ADDRESS BLOCK to receive address
   en_rec        = 1'b0; // Do not allow I_O_BUFFER to receive data   
   w_byte1       = 1'b0;
   w_byte2       = 1'b0;
   w_71h_1       = 1'b0;  // signals are used to control WRITE 71H CMD 
   w_71h_2       = 1'b0;
   w_71h_3       = 1'b0;
   unxp_sck1     = 1'b0;
   unxp_sck2     = 1'b0;
   r_byte1       = 1'b0; // Signals are used to control READ 65H & READ BYTE 1  
   r_65h_1       = 1'b0;
   r_65h_2       = 1'b0;
   r_65h_3       = 1'b0;
   sc_out_valid  = 1'b0;
   r_buffer      = 1'b0; // Signals are used to control "Read & Write DATA BUFFER"
   buf_out_valid = 1'b0;
   w_buffer      = 1'b0;
   spi           = 1'b0;// Signals are used to control MODE & WEL    
   opi           = 1'b0; 
   en_wel        = 1'b0;
   dis_wel       = 1'b0;
   r_sector      = 1'b0; // Signals are used to control Sector Protection Regs 
   prot          = 1'b0;
   unprot        = 1'b0;
   r_03h         = 1'b0; // Signals are used to control Read Array 
   r_0Bh_0Ch     = 1'b0;
   first_read    = 1'b0;
   read_mem      = 1'b0;
   read_mem_valid= 1'b0;
   analog_on1    = 1'b0;
   eq            = 1'b0;
   load_storage2 = 1'b0;
   read_storage2 = 1'b0;
   wrap_8byte    = 1'b0;
   wrap_con      = 1'b0;
   con_8byte1    = 1'b0;
   con_8byte2    = 1'b0;
   incr_addr     = 1'b0;
   program_set   = 1'b0;
   save_start_addr=1'b0;
   erase_set     = 1'b0;
   case(pstate) 
      STATE_REC_OP :begin 
                       en_opcode = 1'b1;                          // Allow Opcode Block to receive opcode input
                       if(finish_opcode) begin 
                          clr_count  = 1'b1;                       // Clear the counter
                          en_opcode  = 1'b0;                       // Stop receiving opcode input  
                          nstate     = STATE_IDLE;
                          if(!program_signal) begin 
                            case(op)
                             CMD_W_ENABLE :begin 
                                              en_wel  = 1'b1; 
                                           end
                             CMD_W_DISABLE:begin 
                                              dis_wel = 1'b1; 
                                           end
                             CMD_SPI      :begin 
                                              spi     = (wel)? 1'b1 : 1'b0; 
                                           end
                             CMD_OPI      :begin 
                                              opi     = (wel)? 1'b1 : 1'b0; 
                                           end
                             CMD_PROTECT  :if(wel) begin 
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1; 
                                           end         
                             CMD_UNPROTECT:if(wel) begin
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end         
                             CMD_W_BYTE1  :if(wel) begin 
                                              nstate  = STATE_RECEIVE;
                                              en_rec  = 1'b1;
                                           end    
                             CMD_W_BYTE2  :if(wel) begin 
                                              nstate  = STATE_RECEIVE;
                                              en_rec  = 1'b1; 
                                           end         
                             CMD_W_71H    :if(wel) begin 
                                              nstate  = STATE_ADDR; 
                                              en_addr = 1'b1;
                                           end    
                             CMD_R_BYTE1  :if(!mode) begin 
                                              nstate       = STATE_SEND; 
                                              r_byte1      = 1'b1;            
                                              sc_out_valid = 1'b1; 
                                           end  
                                           else begin
                                              nstate  = STATE_DUMMY;
                                           end
                             CMD_R_65H    :begin 
                                              nstate  = STATE_ADDR;  
                                              en_addr = 1'b1; 
                                           end       
                             CMD_R_SECTOR :begin 
                                              nstate  = STATE_ADDR;  
                                              en_addr = 1'b1; 
                                           end       
                             CMD_R_BUFFER :if(!mode) begin  // This cmd is only supported in SPI mode
                                              nstate  = STATE_ADDR;  
                                              en_addr = 1'b1; 
                                           end
                             CMD_W_BUFFER :if(wel) begin
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end
                             CMD_PROGRAM  :if(wel) begin
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end
                             CMD_R_03H    :if(!mode) begin
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end
                             CMD_R_0BH    :begin 
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end
                             CMD_R_0CH    :if(mode) begin
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end 
                             CMD_ERASE    :if(wel) begin
                                              nstate  = STATE_ADDR;
                                              en_addr = 1'b1;
                                           end
                            endcase
                          end
                          else begin
                             if(op == CMD_R_BYTE1) begin
                                 if(!mode) begin 
                                    nstate       = STATE_SEND; 
                                    r_byte1      = 1'b1;            
                                    sc_out_valid = 1'b1; 
                                 end  
                                 else begin
                                    nstate  = STATE_DUMMY;
                                 end
                             end 
                             if(op == CMD_R_65H) begin 
                                    nstate  = STATE_ADDR;  
                                    en_addr = 1'b1; 
                             end       
                          end 
                       end
                    end
      STATE_ADDR :begin
                    en_addr = 1'b1;
                    case(op) 
                        CMD_PROTECT  :if(finish_4byte) begin
                                         clr_count     = 1'b1;               //  Clear the counter
                                         en_addr       = 1'b0;
                                         prot          = 1'b1;               //  Protect sector
                                         dis_wel       = 1'b1;               //  WEL bit is set back to 0
                                      end
                        CMD_UNPROTECT:if(finish_4byte) begin 
                                         clr_count     = 1'b1;               //  Clear the counter
                                         en_addr       = 1'b0;
                                         unprot        = 1'b1;               //  Unprotect sector
                                         dis_wel       = 1'b1;               //  WEL bit is set back to 0    
                                      end
                        CMD_W_71H    :if(finish_1byte) begin                 // Write 71h
                                         clr_count     = 1'b1;               // Clear the counter
                                         en_addr       = 1'b0;
                                         nstate        = STATE_RECEIVE;      // Next state : RECEIVE DATA
                                         en_rec        = 1'b1;               
                                      end
                        CMD_R_65H    :if(finish_1byte) begin                 // Read 65h  
                                         clr_count     = 1'b1;               // Clear the counter 
                                         en_addr       = 1'b0;
                                         nstate        = STATE_DUMMY;        // Next state : STATE_DUMMY 
                                      end
                        CMD_R_SECTOR :if(finish_4byte) begin       
                                         en_addr       = 1'b0;
                                         clr_count     = 1'b1;               // Clear the counter   
                                         if(mode) begin                      // OPI Mode 
                                            nstate     = STATE_DUMMY;        // Next state : STATE_DUMMY
                                         end
                                         else if(!mode)begin                 // SPI Mode  
                                            nstate     = STATE_SEND;         
                                            r_sector   = 1'b1;               // Start Reading Sector Protection
                                         end
                                      end
                       CMD_R_BUFFER : if(finish_4byte) begin                 // Received 4 byte of address 
                                         en_addr       = 1'b0;
                                         clr_count     = 1'b1;               // Clear the counter   
                                         nstate        = STATE_DUMMY;        // Next state : STATE_DUMMY
                                      end
                       CMD_W_BUFFER : if(finish_4byte) begin                 // Received 4 byte of address 
                                         en_addr       = 1'b0;
                                         clr_count     = 1'b1;               // Clear the counter   
                                         nstate        = STATE_RECEIVE;      
                                         en_rec        = 1'b1;               //Start receiving data
                                      end
                       CMD_PROGRAM : if(finish_4byte) begin                 // Received 4 byte of address 
                                        clr_count     = 1'b1;               // Clear the counter   
                                        save_start_addr= 1'b1;
                                        if(protect_signal)
                                           nstate      = STATE_IDLE;
                                        else begin
                                           en_addr       = 1'b0;
                                           nstate        = STATE_RECEIVE;      
                                           en_rec        = 1'b1;               //Start receiving data
                                        end
                                      end
                       CMD_R_03H    : begin
                                         analog_on1    = 1'b1; 
                                         if(finish_20bit) begin
                                            r_03h      = 1'b1;       // capture first 18-bit memory address 
                                            eq         = 1'b1;       // load data from memory array
                                         end
                                         if (finish_24bit) begin
                                            clr_count      = 1'b1;
                                            en_addr        = 1'b0;   //stop receiving address 
                                            first_read     = 1'b1;
                                            read_mem       = 1'b1;
                                            read_mem_valid = 1'b1;
                                            nstate         = STATE_SEND;
                                         end
                                      end
                       CMD_R_0BH    : begin
                                         analog_on1    = 1'b1;
                                         if(finish_4byte) begin 
                                            en_addr    = 1'b0;
                                            clr_count  = 1'b1;
                                            nstate     = STATE_DUMMY;
                                            r_0Bh_0Ch  = 1'b1;        // Capture read 0BH address
                                         end   
                                      end 
                       CMD_R_0CH    : begin 
                                         analog_on1    = 1'b1;
                                         if(finish_4byte) begin
                                            en_addr    = 1'b0;
                                            clr_count  = 1'b1;
                                            nstate     = STATE_DUMMY;
                                            r_0Bh_0Ch  = 1'b1;        // Capture read 0CH address
                                         end
                                      end
                       CMD_ERASE    : begin
                                         if(finish_4byte) begin
                                            clr_count  = 1'b1;               // Clear the counter   
                                            nstate     = STATE_IDLE;
                                            dis_wel    = 1'b1;
                                            if(!protect_signal) begin
                                               en_addr   = 1'b0;
                                               erase_set = 1'b1;
                                            end
                                         end
                                      end   
                     endcase 
                  end
      STATE_DUMMY  :case(op)
                       CMD_R_65H    : if(finish_r65h_dummy) begin   
                                         clr_count     = 1'b1;        // Clear the counter
                                         nstate        = STATE_SEND; 
                                         r_65h_1       = 1'b1;        // read the first byte  of data (read 65h) 
                                         sc_out_valid  = 1'b1;      
                                      end
                       CMD_R_BYTE1  : if(finish_4dumbyte)  begin 
                                         clr_count     = 1'b1;                           
                                         nstate        = STATE_SEND; 
                                         r_byte1       = 1'b1; 
                                      end  
                       CMD_R_SECTOR : if(finish_4dumbyte) begin
                                         clr_count     = 1'b1;
                                         nstate        = STATE_SEND; 
                                         r_sector      = 1'b1; 
                                      end 
                       CMD_R_BUFFER : begin 
                                         if(finish_8dumclk) begin
                                            r_buffer      = 1'b1;
                                            buf_out_valid = 1'b1;
                                            clr_count     = 1'b1;
                                            nstate        = STATE_SEND;
                                         end
                                      end  
                       CMD_R_0BH    : begin
                                         analog_on1    = 1'b1;
                                         eq            = finish_1clk; // eq = 1'b1 during first clock   
                                         if(!mode) begin              //Read 0BH:  SPI mode
                                            if(finish_8dumclk) begin
                                               clr_count  = 1'b1;  
                                               first_read = 1'b1;  
                                               read_mem   = 1'b1;
                                               read_mem_valid =1'b1;
                                               nstate     = STATE_SEND;
                                            end
                                         end
                                         else if(mode) begin //READ 0BH OPI / 8 dummy clks
                                            if(r0bh_big_addr)    // if address > 9/10/11/12
                                               nstate     = STATE_R0BH_1;
                                            else if(finish_read_dummy)begin      
                                               clr_count  = 1'b1;
                                               first_read = 1'b1;
                                               read_mem   = 1'b1;
                                               nstate     = STATE_SEND;
                                            end 
                                         end 
                                      end
                       CMD_R_0CH    : begin
                                         analog_on1 = 1'b1;
                                         eq         = finish_1clk;
                                         if(finish_read_dummy) begin
                                            clr_count = 1'b1;
                                            first_read= 1'b1;
                                            read_mem  = 1'b1;
                                            nstate    = STATE_SEND;
                                         end
                                      end
                    endcase
      STATE_SEND   :case(op)
                       CMD_R_BYTE1  : begin
                                         r_byte1   = 1'b1;
                                      end   
                       CMD_R_65H    : if(finish_1byte) begin       // Readed 1 byte of data
                                         clr_count        = 1'b1;  
                                         nstate           = STATE_R65H_2;
                                         r_65h_2          = 1'b1;  // Read the next byte of data (read 65h cmd)
                                         sc_out_valid     = 1'b1;
                                      end
                                      else begin 
                                         r_65h_1   = 1'b1;
                                      end
                       CMD_R_SECTOR : begin 
                                         r_sector  = 1'b1;
                                      end  
                       CMD_R_BUFFER : begin
                                         r_buffer  = 1'b1;
                                         if(finish_1byte) begin //Readed 1 byte of data
                                            clr_count     = 1'b1;
                                            buf_out_valid = 1'b1;
                                         end
                                      end
                       CMD_R_03H    : begin
                                         analog_on1 = 1'b1;
                                         read_mem   = 1'b1;
                                         eq         = finish_1clk?load_data:1'b0;
                                         if(finish_1byte)  begin
                                            clr_count     = 1'b1;
                                            read_mem_valid= 1'b1;
                                         end
                                      end 
                       CMD_R_0BH    : begin
                                         analog_on1 = 1'b1; 
									     read_mem   = 1'b1;
                                         if(!mode) begin                  // Read 0Bh SPI mode    
                                            eq      = finish_1clk?load_data:1'b0;
                                            if(finish_1byte) begin 
                                               clr_count     = 1'b1;
                                               read_mem_valid= 1'b1;
                                            end
                                         end   
                                         else begin
                                            eq     = load_data;
                                         end 
                                      end  
                       CMD_R_0CH    : begin
                                         analog_on1 = 1'b1;
                                         read_mem   = 1'b1;
                                         wrap_8byte =wrap_around_8byte;// wrap around 8 bytes mode   
                                         if(wrap_con_16byte || wrap_con_8byte) begin //wrap continuous16bytes mode
                                            analog_on1 = 1'b1;
                                            read_mem   = 1'b1;
                                            wrap_con   = 1'b1;
                                            if(wrap_con_8byte) begin // wrap continous 8 bytes mode
                                               con_8byte1 = !addr_gt_7;
                                               con_8byte2 =  addr_gt_7;
                                            end   
                                            if(load_data_0Ch) begin
                                               incr_addr = 1'b1;
                                               nstate    = STATE_R0CH_1;
                                            end
                                         end
                                      end
                    endcase
      STATE_R0CH_1: begin 
                       analog_on1 = 1'b1;
                       read_mem   = 1'b1;
                       wrap_con   = 1'b1;
                       eq         = 1'b1;
                       nstate     = STATE_R0CH_2;
                       if(wrap_con_8byte) begin // wrap continous 8 bytes mode
                          con_8byte1 = !addr_gt_7;
                          con_8byte2 =  addr_gt_7;
                       end   
                    end
      STATE_R0CH_2: begin
                       analog_on1 = 1'b1;
                       read_mem   = 1'b1;
                       if(wrap_con_16byte) begin // wrap continuous 16 bytes mode
                          wrap_con= 1'b1;
                          if(reach_lastbyte) begin
                             nstate  = STATE_R0CH_3;
                          end                    
                       end
                       else if(addr_gt_7) begin               // wrap continuous 8bytes mode
                          con_8byte2  = 1'b1;
                          wrap_con    = 1'b1;
                          eq          = load_data;
                          if(reach_lastbyte) begin
                             nstate   = STATE_R0CH_3;
                          end  
                       end 
                       else if(!addr_gt_7) begin
                          con_8byte1  = 1'b1;
                          wrap_con    = 1'b1;
                          eq          = load_data;
                          if(reach_lastbyte) begin
                             nstate   = STATE_R0CH_4;
                          end  
                       end 
                    end   

      STATE_R0CH_3: begin
                       analog_on1 = 1'b1;
                       read_mem   = 1'b1;
                       if(wrap_con_16byte) begin // wrap continuous 16 bytes mode  
                          eq      = load_data;
                       end
                       else begin                // wrap continuous 8 bytes mode
                          eq      = load_data;
                          con_8byte1 = 1'b1;
                          if(reach_lastbyte) begin
                             nstate  = STATE_R0CH_4; 
                          end
                       end    
                    end  
      STATE_R0CH_4: begin
                       analog_on1 = 1'b1;
                       read_mem   = 1'b1;
                       con_8byte2 = 1'b1;
                       eq         = load_data;
                       if(reach_lastbyte) begin
                          nstate  = STATE_R0CH_3;
                       end  
                    end      
      STATE_R0BH_1: begin                        // The case address > 9/10/11/12
                       analog_on1 = 1'b1;
                       if(mode_8dumclk) begin
                          if(finish_4dumclk) begin
                             load_storage2 = 1'b1;
                             nstate        = STATE_R0BH_2; 
                          end 
                       end
                       else if(mode_10dumclk) begin
                          if(finish_5dumclk) begin
                             load_storage2 = 1'b1;
                             nstate        = STATE_R0BH_2; 
                          end 
                       end
                       else if(mode_12dumclk) begin
                          if(finish_6dumclk) begin
                             load_storage2 = 1'b1;
                             nstate        = STATE_R0BH_2; 
                          end 
                       end
                       else if(mode_14dumclk) begin
                          if(finish_7dumclk) begin
                             load_storage2 = 1'b1;
                             nstate        = STATE_R0BH_2; 
                          end 
                       end
                       else if(mode_16dumclk) begin
                          if(finish_7dumclk) begin
                             load_storage2 = 1'b1;
                             nstate        = STATE_R0BH_2; 
                          end 
                       end
                    end 
      STATE_R0BH_2 :begin                             
                       eq         = 1'b1;
                       analog_on1 = 1'b1;
                       nstate     = STATE_R0BH_3;
                    end
      STATE_R0BH_3 :begin
                       analog_on1 = 1'b1;
                       if(finish_read_dummy) begin 
                          clr_count   = 1'b1;  
                          first_read  = 1'b1;  
                          read_mem    = 1'b1;
                          read_storage2 = 1'b1;
                          nstate      = STATE_R0BH_4;
                       end
                    end   
      STATE_R0BH_4 :begin
                       read_mem      = 1'b1; 
                       analog_on1    = 1'b1;
                       read_storage2 = !addr_eq_15; 
                       if(reach_lastbyte) begin
                          nstate      = STATE_SEND;
                       end
                    end     
      STATE_R65H_2 : if(finish_1byte) begin
                        clr_count    = 1'b1;
                        nstate       = STATE_R65H_3;
                        r_65h_3      = 1'b1;         // Start reading the last byte of data ( read 65h cmd)
                        sc_out_valid = 1'b1;
                     end
                     else begin 
                        r_65h_2      = 1'b1;
                     end 
      STATE_R65H_3:  begin
                        r_65h_3      = 1'b1;         // Keep reading the last byte of data ( read 65h cmd)  
                        if(finish_1byte) begin
                           clr_count    = 1'b1;
                           sc_out_valid = 1'b1;
                        end
                     end 
      STATE_RECEIVE: case(op)
                        CMD_W_BYTE1 :if(finish_1byte) begin
                                        clr_count    = 1'b1;
                                        w_byte1      = 1'b1;
                                        nstate       = STATE_WBYTE1;
                                     end
                                     else begin
                                        en_rec       = 1'b1;
                                     end  
                        CMD_W_BYTE2 :if(finish_1byte) begin
                                        clr_count    = 1'b1;
                                        w_byte2      = 1'b1;
                                        nstate       = STATE_WBYTE2;
                                     end
                                     else begin
                                        en_rec       = 1'b1;  
                                     end
                        CMD_W_71H   :begin
                                        en_rec       = 1'b1; 
                                        if (finish_1byte) begin
                                           w_71h_1   = 1'b1;            // Received 1 byte of data 
                                           clr_count = 1'b1;
                                           nstate    = STATE_REC_71H_2;
                                        end
                                     end
                        CMD_W_BUFFER:begin
                                        w_buffer     = 1'b1;
                                        en_rec       = 1'b1;   
                                        if(finish_1byte) begin
                                           clr_count = 1'b1;
                                        end
                                     end    
                        CMD_PROGRAM :begin
                                        dis_wel      = 1'b1;
                                        w_buffer     = 1'b1;
                                        en_rec       = 1'b1;
                                        program_set  = 1'b1;   
                                        if(finish_1byte) begin
                                           clr_count = 1'b1;
                                        end
                                     end    
                     endcase   
      STATE_WBYTE1:  begin
                        w_byte1      = 1'b1;
                     end  
      STATE_WBYTE2:  begin
                        w_byte2      = 1'b1;
                     end
      STATE_REC_71H_2:begin 
                        en_rec       = 1'b1;
                        if (finish_1byte) begin      
                           w_71h_2   = 1'b1;      // Received 2 bytes of data 
                           clr_count = 1'b1;
                           nstate    = STATE_REC_71H_3;
                        end
                        else begin
                           unxp_sck1 = 1'b1;      // unexpected sck after the first byte of data was received
                           w_71h_1   = 1'b1;
                        end
                      end
      STATE_REC_71H_3:begin
                         if (finish_1byte) begin
                            w_71h_3  = 1'b1;      // Received 3 bytes of data
                            nstate   = STATE_REC_71H_4;
                         end
                         else begin 
                            unxp_sck2= 1'b1;      // unexpected sck after the second byte of data was received 
                            w_71h_2  = 1'b1;
                            en_rec   = 1'b1; 
                         end   
                      end
      STATE_REC_71H_4:begin
                         w_71h_3     = 1'b1;
                      end   
   endcase           
end
endmodule
