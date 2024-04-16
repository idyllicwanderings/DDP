`timescale 1ns / 1ps


`define ADDER_W 180
`define ADDER_NUM 2

module adder_wbit(
//                   input  wire  resetn,
//                   input  wire  EN,
                   input  wire  [`ADDER_W-1:0] A,
                   input  wire  [`ADDER_W-1:0] B,
                   input  wire  cin,
                   output wire  [`ADDER_W-1:0] S,
                   output wire  cout);
    
//    reg [`ADDER_W-1:0] reg_A;
//    reg [`ADDER_W-1:0] reg_B;
//    reg reg_cin;
//    always @(posedge clk)
//    begin
////        if(~resetn) {reg_A, reg_B, reg_cin} <= {1'b0,1'b0,1'b0};
////        else 
//            if (EN)
//            begin
//            reg_A <= A; reg_B <= B; reg_cin <= cin;
//            end
//    end
    assign {cout, S} = A + B + cin;
      
//    reg [`ADDER_W-1:0] reg_S;
//    reg reg_C;
    
//    always @(posedge clk)
//    begin
//        if(~resetn) {reg_C, reg_S} <= {1'b0,1'b0};
//        else if (EN)
//            begin
//            {reg_C, reg_S} <= A + B + cin;
//            end
//    end
    
//    assign cout = reg_C;
//    assign S    = reg_S;
    
endmodule

module adder_msb(
//                       input  wire  resetn,
//                       input  wire  EN,
                       input  wire  [513-`ADDER_W*`ADDER_NUM:0] A,
                       input  wire  [513-`ADDER_W*`ADDER_NUM:0] B,
                       input  wire  cin,
                       output wire  [513-`ADDER_W*`ADDER_NUM:0] S,
                       output wire  cout);
    
//    reg [1026-`ADDER_W*`ADDER_NUM:0]reg_S;
//    reg reg_C;
    
//    always @(posedge clk)
//    begin
//        if(~resetn) {reg_C, reg_S} <= {1'b0,1'b0};
//        else if (EN)
//            begin
//            {reg_C, reg_S} <= A + B + cin; 
//            end
//    end
    
//    reg [1026-`ADDER_W*`ADDER_NUM:0] reg_A;
//    reg [1026-`ADDER_W*`ADDER_NUM:0] reg_B;
//    reg reg_cin;
//    always @(posedge clk)
//    begin
////        if(~resetn) {reg_A, reg_B, reg_cin} <= {1'b0,1'b0,1'b0};
////        else 
//            if (EN)
//            begin
//            reg_A <= A; reg_B <= B; reg_cin <= cin;
//            end
//    end
    assign {cout, S} = A + B + cin;
    
//    assign cout = reg_C;
//    assign S    = reg_S;
    
endmodule

module adder_514(
//        input  wire          clk,
//        input  wire          resetn,
//        input  wire          start,
        input  wire          carry_in,
        input  wire [513:0] in_a,
        input  wire [513:0] in_b,
        output wire [513:0] result,
        output wire  carry_out
//        output wire          done
        );
        
        wire cin;
        reg EN;
        
        assign cin = carry_in;
        
        wire [`ADDER_NUM:0] carries;
        wire [513:0] next_result;
        wire [513:0] sum0,sum1;
        wire [`ADDER_NUM:0] carry0,carry1;
//        assign in_b_xor = in_b ^ {1027{subtract}}; //sub=1: in_b = ~in_b; sub=0: in_b=in_b
//        assign in_b_xor = (subtract) ? ~in_b : in_b; 
        genvar i;
        generate
        for (i = 0; i < `ADDER_NUM + 1; i = i + 1) 
            begin
            if (i == 0) begin
                adder_wbit adder_0( in_a, in_b, cin, next_result[`ADDER_W-1:0], carries[0]);
            end
            
            else if (i > 0 & i < `ADDER_NUM) begin
                adder_wbit adder_c0( (in_a >> (`ADDER_W*i)), (in_b >> (`ADDER_W*i)), 1'b0, sum0[`ADDER_W*i + `ADDER_W-1 : `ADDER_W*i], carry0[i]);
                adder_wbit adder_c1( (in_a >> (`ADDER_W*i)), (in_b >> (`ADDER_W*i)), 1'b1, sum1[`ADDER_W*i + `ADDER_W-1 : `ADDER_W*i], carry1[i]);
                assign carries[i] = carries[i-1] ? carry1[i] : carry0[i];
                assign next_result[`ADDER_W*i + `ADDER_W-1 : `ADDER_W*i] = carries[i-1] ? sum1[`ADDER_W*i + `ADDER_W-1 : `ADDER_W*i] : sum0[`ADDER_W*i + `ADDER_W-1 : `ADDER_W*i];
            end
            
            else begin
                adder_msb adder_msb_c0( (in_a >> (`ADDER_W*`ADDER_NUM)), (in_b >> (`ADDER_W*`ADDER_NUM)), 1'b0, sum0[513:`ADDER_W*`ADDER_NUM], carry0[`ADDER_NUM]);
                adder_msb adder_msb_c1( (in_a >> (`ADDER_W*`ADDER_NUM)), (in_b >> (`ADDER_W*`ADDER_NUM)), 1'b1, sum1[513:`ADDER_W*`ADDER_NUM], carry1[`ADDER_NUM]);
                assign carries[`ADDER_NUM] =  carries[`ADDER_NUM-1] ? carry1[`ADDER_NUM] : carry0[`ADDER_NUM];
                assign next_result[513:`ADDER_W*`ADDER_NUM] = carries[`ADDER_NUM-1] ? sum1[513:`ADDER_W*`ADDER_NUM] : sum0[513:`ADDER_W*`ADDER_NUM];
            end
        
        end
        endgenerate
        
//        assign next_result[1027]  = carries[`ADDER_NUM];
        assign carry_out  = carries[`ADDER_NUM];
                
//        reg [1027:0] reg_result;
        
//        always @(posedge clk)
//        begin
////            if(~resetn) reg_result  <=  1'd0;
////            else        
//            reg_result  <=  next_result;
//        end
        
//        assign result = done ? reg_result : 1028'b0;
        assign result = next_result;
        
//        reg state, nextstate;
       
//        always @(*)
//        begin
//            state <= start;
//        end
        
//        always @(*)
//        begin
//            case(state)
//                // Idle state
//                1'b0:    EN <= 1'b0;
//                // Compute state
//                1'b1:    EN <= 1'b1;
//            endcase
//        end
        
//        reg regDone;
//        reg midDone;
        
//        always @(posedge clk)
//        begin
////            if(~resetn) midDone <= 1'b0;
////            else        
//            midDone <= (state==1'b1) ? 1'b1 : 1'b0;
//        end
        
//        always @(posedge clk)
//        begin
////            if(~resetn) regDone <= 1'b0;
////            else        
//            regDone <= midDone;
//        end
        
//        assign done = regDone;
        
        
    endmodule

