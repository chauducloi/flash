module  fsm2 
 ( 
   input          clkm,
   input          program_signal,
   input          erase_signal,
   input          cs,
   output   reg   en_wr,
   output   reg   erase,
   output   reg   erase_clr,
   output   reg   analog_on2
 );

parameter  STATE_IDLE        =  3'D0,
           STATE_PROGRAM1    =  3'D1,
           STATE_PROGRAM2    =  3'D2,
           STATE_ERASE1      =  3'D3,
           STATE_ERASE2      =  3'D4;

reg    [1:0]  nstate;
reg    [1:0]  pstate;

always@(posedge clkm)
begin
   if(program_signal) 
      pstate <= nstate;
   else 
      pstate <= STATE_IDLE;
end

always@(*) 
begin
   nstate      = pstate;
   en_wr       = 1'b0;
   analog_on2  = 1'b0;
   erase       = 1'b0;
   erase_clr   = 1'b0;
   case(pstate) 
      STATE_IDLE:    begin 
                        if(program_signal && cs) begin
                           nstate     = STATE_PROGRAM1;
                           analog_on2 = 1'b1;
                        end
                        else if(erase_signal && cs) begin
                           analog_on2 = 1'b1;
                           nstate     = STATE_ERASE1;
                           erase      = 1'b1;
                        end 
                     end
      STATE_PROGRAM1: begin
                        if(program_signal) begin  
                           nstate     = STATE_PROGRAM2;    
                           analog_on2 = 1'b1;    
                        end
                        else begin
                           nstate     = STATE_IDLE;
                        end
                     end    
      STATE_PROGRAM2: begin
                        if(program_signal) begin  
                           nstate     = STATE_PROGRAM1;    
                           en_wr      = 1'b1;
                           analog_on2 = 1'b1;    
                        end
                        else begin
                           nstate     = STATE_IDLE;
                        end
                     end   
      STATE_ERASE1:
                     begin 
                        analog_on2 = 1'b1;    
                        erase      = 1'b1;
                        nstate     = STATE_ERASE2;
                     end  
      STATE_ERASE2:
                     begin 
                        analog_on2 = 1'b1;    
                        erase      = 1'b1;
                        erase_clr  = 1'b1;
                        nstate     = STATE_IDLE; 
                     end 
   endcase
end
endmodule 
