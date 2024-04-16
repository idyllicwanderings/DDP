`timescale 1ns / 1ps

module adder_cycle(
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire          subtract,
  input  wire [1026:0] in_a,
  input  wire [1026:0] in_b,
  output reg  [1027:0] resultAdd,
  output wire          done,
  output wire          midDone
  );
    
    reg           regA_en;
    wire [1027:0] regA_D;
    reg  [1027:0] regA_Q;
    always @(posedge clk)
    begin
        if(~resetn)         regA_Q <= 1028'd0;
        else if (regA_en)   regA_Q <= regA_D;
    end

    // Task 2
    // Describe a 128-bit register for B

    reg           regB_en;
    wire [1027:0] regB_D;
    reg  [1027:0] regB_Q;
    always @(posedge clk)
    begin
        if(~resetn)          regB_Q <= 1028'd0;
        else if (regB_en)    regB_Q <= regB_D;
    end

    // Task 3
    // Describe a 2-input 128-bit Multiplexer for A
    // It should select either of these two:
    //   - the input A
    //   - the output of regA shifted-right by 64
    // Also connect the output of Mux to regA's input
    // (Implemented below already for you, be sure you understand it)

    reg           muxA_sel;
    wire [1027:0] muxA_Out;
    assign muxA_Out = (muxA_sel == 0) ? in_a : {514'b0,regA_Q[1027:514]};

    assign regA_D = muxA_Out;

    // Task 4
    // Describe a 2-input 64-bit Multiplexer for B
    // !! Use always statement for combinatorial logic this

                
    reg           muxB_sel;
    wire [1027:0] muxB_Out;
    wire [1027:0] inputB;
    reg subtract_sel;
    assign inputB = (subtract == 0) ? {1'b0, in_b} : {1'b1, ~in_b };//-----X
    assign muxB_Out = (muxB_sel == 0) ? inputB : {514'b0,regB_Q[1027:514]};//-----X
    assign regB_D = muxB_Out;

    // Task 5
    // Describe an adder
    // It should be a combinatorial logic:
    // Its inputs are two 64-bit operands and 1-bit carry-in
    // Its outputs are one 64-bit result  and 1-bit carry-out

    wire [513:0] operandA;
    wire [513:0] operandB;
    wire         carry_in;
    wire [513:0] result;
    wire         carry_out;

//    assign {carry_out,result} = operandA + operandB + carry_in;
    adder_514 adder1 (carry_in, operandA, operandB, result,carry_out); 
    // Task 6
    // Describe a 128-bit register for storing the result
    // The register should store adder's outputs at the msb 64-bits
    // and the shift the previous 64 msb bits to lsb.

    reg           regResult_en;
    reg  [1027:0] regResult;
    always @(posedge clk)
    begin
        if(~resetn)             regResult <= 1027'b0;
        else if (regResult_en)  regResult <= {result, regResult[1027:514]};
    end

    // Task 7
    // Describe a 1-bit register for storing the carry-out

    reg  regCout_en;
    reg  regCout;
    always @(posedge clk)
    begin
        if(~resetn)          regCout <= 1'b0;
        else if (regCout_en) regCout <= carry_out;
    end

    // Task 8
    // Describe a 1-bit multiplexer for selecting carry-in
    // It should select either of these two:
    //   - 0
    //   - carry-out

    reg  muxCarryIn_sel;
    wire muxCarryIn;

    assign muxCarryIn = (muxCarryIn_sel == 0) ? subtract : regCout;

    // Task 9
    // Connect the inputs of adder to the outputs of A and B registers
    // and to the carry mux

                assign operandA = regA_Q;
                assign operandB = regB_Q;
                assign carry_in = muxCarryIn;


    // Task 10
    // Describe output, concatenate the registers of carry_out and result

    always @(*)
    begin
        resultAdd <= {regCout, regResult};
    end
    // Task 11
    // Describe state machine registers
    // (Implemented below already for you, be careful with their width.
    // Think about how many bits you will need.)

    reg [1:0] state=2'd0, nextstate;
    
    always @(posedge clk)
    begin
        if(~resetn)	state <= 2'd0;
        else        state <= nextstate;
    end
    
    
    // Task 12
    // Define your states
    // Describe your signals at each state
    always @(*)
    begin
        case(state)

            // Idle state; Here the FSM waits for the start signal
            // Enable input registers to fetch the inputs A and B when start is received
            2'd0: begin
                regA_en        <= 1'b1;
                regB_en        <= 1'b1;
                regResult_en   <= 1'b0;
                regCout_en     <= 1'b0;
                muxA_sel       <= 1'b0;
                muxB_sel       <= 1'b0;
                muxCarryIn_sel <= 1'b0;
            end

            // Add low:
            // Disable input registers
            // Calculate the first addition
            2'd1: begin
                regA_en        <= 1'b1;
                regB_en        <= 1'b1;
                regResult_en   <= 1'b1;
                regCout_en     <= 1'b1;
                muxA_sel       <= 1'b1;
                muxB_sel       <= 1'b1;
                muxCarryIn_sel <= 1'b0;
            end

            // Add-High state:
            // Calculate the second addition
            2'd2: begin
                regA_en        <= 1'b0;
                regB_en        <= 1'b0;
                regResult_en   <= 1'b1;
                regCout_en     <= 1'b1;
                muxA_sel       <= 1'b1;
                muxB_sel       <= 1'b1;
                muxCarryIn_sel <= 1'b1;
            end

            default: begin
                regA_en        <= 1'b0;
                regB_en        <= 1'b0;
                regResult_en   <= 1'b1;
                regCout_en     <= 1'b0;
                muxA_sel       <= 1'b0;
                muxB_sel       <= 1'b0;
                muxCarryIn_sel <= 1'b0;
            end

        endcase
    end

    // Task 13
    // Describe next_state logic

    always @(*)
    begin
        case(state)
            2'd0: begin
                if(start)
                    nextstate <= 2'd1;
                else
                    nextstate <= 2'd0;
                end

                2'd1   : nextstate <= 2'd2;
                2'd2   : nextstate <= 2'd0;
                default: nextstate <= 2'd0;
        endcase
    end
    
    // Task 14
    // Describe done signal
    // It should be high at the same clock cycle when the output ready

    reg regDone;
    always @(posedge clk)
    begin
        if(~resetn) regDone <= 1'd0;
        else        regDone <= (state==2'd2) ? 1'b1 : 1'b0;
    end

    assign done = regDone;
    assign midDone = (state==2'd2) ? 1'b1 : 1'b0;

endmodule