`timescale 1ns / 1ps

module montgomery(
  input           clk,
  input           resetn,
  input           start,
  input  [1023:0] in_a,
  input  [1023:0] in_b,
  input  [1023:0] in_m,
  output [1023:0] result,
  output          done
    );

  reg [1027:0] regC;
  reg [1:0]    mux_sel;
  reg [1:0]    C_sel;
  reg [1:0]    C_sel_next;
  reg [1026:0] operandA;
  reg [1026:0] operandB;
  reg subtract;
  reg startAdd;
  reg startAdd_next;
  wire [1027:0] resultAdd;
  wire doneAdd;
  wire midDoneAdd;
  
   reg [10:0]     regN;
   reg [10:0]     regN_next;
    
      reg  [1023:0] input_a;
  reg  [1023:0] input_b;
  reg  [1023:0] input_a_next;
  reg  [1023:0] input_b_next;
  reg startMont;
    
   always @(posedge clk)
    begin       
            startMont <= start;
    end
  
   always @(posedge clk)
    begin       
            input_a <= input_a_next;
            input_b <= input_b_next;
    end
  
   always @(*)
    begin       
        if (startMont) begin
            input_a_next <= in_a; 
            input_b_next <= in_b;end
        else begin
            input_a_next <= input_a;
            input_b_next <= input_b; end
    end
    
    always @(posedge clk)
    begin
        if(~resetn  || startMont)	regN <= 10'd0;
        else        regN <= regN_next;
    end
    
    always @(*)
    begin
        operandA <= regC;
    end
    
    wire a;
    assign a = (input_a >> regN);
    always @(*)
    begin
    case (mux_sel)
        2'b01: begin     operandB <= (a ? input_b : 0);     end
        2'b10: begin     operandB <= 0;                  end
        2'b11: begin     operandB <= in_m;               end
        2'b00: begin     operandB <= 0;                  end
        default: begin   operandB <= 0;                  end
    endcase 
  end
  
  adder_cycle adder1 (clk, resetn, startAdd, subtract, operandA, operandB, resultAdd, doneAdd, midDoneAdd); 
  
  reg [1027:0] regC_last;reg [1027:0] regC_store;reg [1027:0] regC_store_next;
  always @(*)
  begin
    if  (~resetn|| startMont)	      regC <= 1028'd0;
    else begin
        if (doneAdd || done) begin
            case (C_sel)
                2'b00: regC <= (resultAdd >> 1);
                2'b01: regC <= resultAdd; 
                2'b10: regC <= regC_store;
                2'b11: regC <= regC_last;
                default: regC <= regC_last;
            endcase
        end
        else regC <= regC_last;
    end
  end
  
   always @(posedge clk)
   begin
        if(~resetn || startMont)	begin regC_last <= 1028'b0; end
        else regC_last <= regC;
   end
  
   reg [1:0] state, nextstate;
   always @(posedge clk)
   begin
        if(~resetn)	state <= 2'd0;
        else        state <= nextstate;
   end

   always @(*)
   begin
       case (state)
           2'b00:   begin mux_sel=2'b00;      subtract = 1'b0;  end
           2'b01:   begin mux_sel=2'b01;      subtract = 1'b0;  end
           2'b10:   begin mux_sel=regC[0]+2;  subtract = 1'b0;  end
           2'b11:   begin mux_sel=2'b11;      subtract = 1'b1;  end
           default: begin mux_sel=2'b00;      subtract = 1'b0;  end
       endcase
   end
   
   always @(posedge clk)
   begin
        if(~resetn)	startAdd <= 1'b0;
        else startAdd <= startAdd_next;
   end
   
   
   always @(posedge clk)
   begin
        C_sel <= C_sel_next;
   end
   
   reg regDone;
   reg regDone_next;
   always @(posedge clk)
   begin
        if(~resetn || startMont)	regDone <= 1'd0;
        else        regDone <= regDone_next;
   end
   reg tmpc; reg tmpc_next;
   always @(posedge clk)
   begin
        if(~resetn|| startMont)	tmpc <= 1'b0;
        else tmpc <= tmpc_next;
   end
   always @(posedge clk)
   begin
        if(~resetn || startMont)	regC_store <= 1028'b0;
        else regC_store <= regC_store_next;
   end
   
   always @(*)
    begin
    regN_next <= regN;
    regDone_next <= 1'b0;
    tmpc_next <= 1'b0;
    regC_store_next <= 1'd0;
        case(state)
            2'b00: begin
                C_sel_next <= 2'b10;
                if(startMont) begin
                    nextstate <= 2'b01;
                    startAdd_next <= 1'b1; 
                    end
                else begin
                    nextstate <= 2'b00; 
                    startAdd_next <= 1'b0;
                    end
                end
            2'b01: begin //initial add: C+A[i]*B
                C_sel_next <= 2'b01;
                if (midDoneAdd) begin
                    nextstate <= 2'b10; 
                    startAdd_next <= 1'b1;
                    regN_next <= regN + 1;end
                else begin
                    nextstate <= 2'b01;
                    startAdd_next <= 1'b0; end
                end
            2'b10: begin
                C_sel_next <= 2'b00; 
                if (midDoneAdd) begin 
                    startAdd_next <= 1'b1;     
                    if (regN < 1024)  nextstate <= 2'b01;     
                    else  nextstate <= 2'b11;      
                end
                else begin 
                    nextstate <= 2'b10;
                    startAdd_next <= 1'b0; end
                end
            2'b11: begin
                if (doneAdd) begin 
                    if (tmpc) begin
                        tmpc_next <= 1'b1;
                        if (resultAdd[1027] == 0) begin 
                            nextstate <= 2'b11; 
                            C_sel_next <= 2'b01; 
                            startAdd_next <= 1'b1;end
                        else begin 
                            nextstate <= 2'b00; 
                            C_sel_next <= 2'b10;
                            regDone_next <= 1; 
                            startAdd_next <= 1'b0; 
                            regC_store_next <= regC_last;end 
                        end   
                    else begin tmpc_next <= 1'b1; 
                        nextstate <= 2'b11; 
                        C_sel_next <=2'b01; 
                        startAdd_next <= 1'b0; 
                        end
                    
                end
                else begin 
                    if (tmpc) tmpc_next <= 1'b1;
                    else tmpc_next <= 1'b0;
                    nextstate <= 2'b11; 
                    C_sel_next <= 2'b01;
                    startAdd_next <= 1'b0; end
                end 
        endcase
   end 

  assign result = done ? regC : 1024'b0;
  assign done = regDone;

endmodule
