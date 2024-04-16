`define CMD_INSTR_BIT           2:0
`define IN_DATA_VALID_BIT       3
`define OUT_TX_READY_BIT        4
`define OUT_DATA_READY_BIT      5
`define OUT_IS_DONE_BIT         6   // is_done
`define IN_DONE_ACK_BIT         7
`define IN_CMD_VALID_BIT        8
`define IN_DATA_READY_BIT       9
//`define IN_PARAM_CNT_BIT        12:10
//`define IN_PARAM_VALID_BIT      13
//`define OUT_PARAM_READY_BIT     14
//`define OUT_CMD_READY_BIT       15
`define IN_PARAM_CNT_BIT        16:14
`define IN_PARAM_VALID_BIT      17
`define OUT_PARAM_READY_BIT     18
`define OUT_CMD_READY_BIT       19


//`define DMA_ISIDLE_BIT 2


`define CMD_IDLE             3'h0
`define CMD_COMP             3'h1
`define CMD_READ_IN          3'h2
`define CMD_WRITE_OUT        3'h3
`define CMD_ENCRYPT          3'h4
`define CMD_DECRYPT          3'h5
    
module rsa (
    input  wire          clk,
    input  wire          resetn,
    output wire   [ 3:0] leds,

    // input registers                     // output registers
    input  wire   [31:0] rin0,             output wire   [31:0] rout0,
    input  wire   [31:0] rin1,             output wire   [31:0] rout1,
    input  wire   [31:0] rin2,             output wire   [31:0] rout2,
    input  wire   [31:0] rin3,             output wire   [31:0] rout3,
    input  wire   [31:0] rin4,             output wire   [31:0] rout4,
    input  wire   [31:0] rin5,             output wire   [31:0] rout5,
    input  wire   [31:0] rin6,             output wire   [31:0] rout6,
    input  wire   [31:0] rin7,             output wire   [31:0] rout7,

    // dma signals
    input  wire [1023:0] dma_rx_data,      output wire [1023:0] dma_tx_data,
    output wire [  31:0] dma_rx_address,   output wire [  31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );


  // In this example three input registers are used.
  // The first one is used for giving a command to FPGA.
  // The others are for setting DMA input and output data addresses.
  wire [31:0] command;
  assign command        = rin0; // use rin0 as command
  assign dma_rx_address = rin1; // use rin1 as input  data  
  assign dma_tx_address = rin2; // use rin2 as output data address

  // Only one output register is used. It will the status of FPGA's execution.
  wire [31:0] status;
  assign rout0 = status; // use rout0 as status
  assign rout1 = 32'b0;  // not used
  assign rout2 = 32'b0;  // not used
  assign rout3 = 32'b0;  // not used
  assign rout4 = 32'b0;  // not used
  assign rout5 = 32'b0;  // not used
  assign rout6 = 32'b0;  // not used
  assign rout7 = 32'b0;  // not used


  // In this example we have only one computation command.
  wire isCmdComp  = (command[`CMD_INSTR_BIT] == `CMD_COMP       & command[`IN_CMD_VALID_BIT]);
  wire isCmdIdle  = (command[`CMD_INSTR_BIT] == `CMD_IDLE       & command[`IN_CMD_VALID_BIT]);
  wire isCmdRead  = (command[`CMD_INSTR_BIT] == `CMD_READ_IN    & command[`IN_CMD_VALID_BIT]);
  wire isCmdWrite = (command[`CMD_INSTR_BIT] == `CMD_WRITE_OUT  & command[`IN_CMD_VALID_BIT]);
  wire isCmdCrypt = (command[`CMD_INSTR_BIT] == `CMD_ENCRYPT    & command[`IN_CMD_VALID_BIT]);
    
    
  wire in_data_valid   = (command[`IN_DATA_VALID_BIT]);  // control ONE dma start to read
//  wire dma_isIdle      = isCmdIdle || isCmdRead || isCmdWrite || isCmdComp;
  wire dma_isDone      = (command[`IN_DONE_ACK_BIT]);
  wire in_data_ready   = (command[`IN_DATA_READY_BIT]);
  wire [2:0] in_param_cnt  = (command[`IN_PARAM_CNT_BIT]);
  wire in_param_valid   = (command[`IN_PARAM_VALID_BIT]);
  wire in_cmd_valid  = command[`IN_CMD_VALID_BIT];  
  wire out_cmd_ready = command[`IN_CMD_VALID_BIT];  
    
  // Define state machine's states
  localparam
    STATE_IDLE     = 3'd0,
    STATE_RX       = 3'd1,
    STATE_RX_WAIT  = 3'd2,
    STATE_COMPUTE  = 3'd3,
    STATE_TX       = 3'd4,
    STATE_TX_WAIT  = 3'd5,
    STATE_DONE     = 3'd6;

  // The state machine
  reg [2:0] state = STATE_IDLE;
  reg [2:0] next_state = STATE_IDLE;
  reg [1023:0] modulusN;
  reg [1023:0] R_mod_N;
  reg [1023:0] A;
  reg [1023:0] regA_D;
  reg [1023:0] regA_Q;
  reg [1023:0] x;
  reg [1023:0] x_tilde;
  reg [1023:0] regx_D;
  reg [1023:0] regx_Q;
  reg [1023:0] R2_mod_N;
  reg [1023:0] e;
  reg [1023:0] in_Mont1_1;
  reg [1023:0] in_Mont1_2;
  reg [1023:0] in_Mont2;
  wire[1023:0] resultMont1;
  wire[1023:0] resultMont2;
  wire         doneMont1;
  wire         doneMont2;
  reg          flag1, flag1_last;
  reg          flag2, flag2_last;
  reg [2:0]    order_in; // count input cycles 
  reg [10:0]   count_e; // count e from bit 0 to bit t 
  reg [10:0]   count_e_next;
  reg          sel_loop; // true if in the for-loop from t down to 0
  reg [1:0]    sel1;
  reg          sel_last; // true if in the last Mont
  reg          sel2;
  reg [1:0]    CompState;
  reg [1:0]    next_CompState;
  reg          startMont1;
  reg          startMont1_next;
  reg          startMont2;
  reg          startMont2_next;
  reg          regDone;
  reg          regDone_next;
  reg          out_data_ready = 1'b0;   // ONE dma read-in OK
  reg          out_param_ready = 1'b0;
//  wire         out_cmd_ready = 1'b0;
  reg [1023:0] r_data = 1024'h0;
  reg [1023:0] r_data_tmp = 1024'h0;
  
  localparam // Define state machine's states in STATE_COMPUTE
    Mont_idle  = 2'd0,
    Mont_1st   = 2'd1,
    Mont_loop  = 2'd2,
    Mont_last  = 2'd3;
  
  always@(*) begin
    // defaults
    next_state      <= STATE_IDLE;
    next_CompState  <= Mont_idle; 
    startMont1_next <= 1'b0;
    startMont2_next <= 1'b0;
//    out_data_ready  <= 1'b0;
    count_e_next    <= 11'd15;
    regDone_next    <= 1'b0;
    
//    modulusN <= modulusN_last; 
//    R_mod_N <= R_mod_N_last; 
//    x <= x_last; 
//    R2_mod_N <= R2_mod_N_last; 
//    e <= e_last;
    
    // state defined logic
    case (state)  
      // Wait in IDLE state till a compute command
      STATE_IDLE: begin
        next_state <= (isCmdRead) ? STATE_RX : STATE_IDLE;
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_RX: begin
        next_state <= (~dma_idle) ? STATE_RX_WAIT : STATE_RX;
      end

      // Wait the completion of dma.
      STATE_RX_WAIT : begin
//        out_data_ready <= 1'b0; 
        {next_state, startMont1_next, next_CompState} <= (dma_done) ? {STATE_RX, 1'b0, Mont_idle} : (isCmdCrypt) ? {STATE_COMPUTE, 1'b1, Mont_1st} : {STATE_RX_WAIT, 1'b0, Mont_idle};
                
//        next_state <= (dma_done) ? STATE_RX : (isCmdCrypt) ? STATE_COMPUTE : state;
//        startMont1_next <= (dma_done) ? 1'b0 : (isCmdCrypt) ? 1'b1 : 1'b0; 
//        next_CompState <= (dma_done) ? Mont_idle : (isCmdCrypt) ? Mont_1st : Mont_idle;
        
//        if (dma_done & in_data_valid & in_param_valid & in_cmd_valid) begin
//            case (order_in)
//                3'd0:    modulusN  <= r_data; 
//                3'd1:     R_mod_N  <= r_data; 
//                3'd2:           x  <= r_data;   
//                3'd3:    R2_mod_N  <= r_data;    
//                3'd4:           e  <= r_data;     
//                default: begin  modulusN <= modulusN_last; R_mod_N <= R_mod_N_last; x <= x_last; 
//                                R2_mod_N <= R2_mod_N_last; e <= e_last; end
//            endcase
//            out_data_ready <= 1'b1;
//        end
//        else begin  modulusN <= modulusN_last; R_mod_N <= R_mod_N_last; x <= x_last; 
//                                R2_mod_N <= R2_mod_N_last; e <= e_last; end
        
      end

      // A state for dummy computation for this example. Because this
      // computation takes only single cycle, go to TX state immediately
      STATE_COMPUTE : begin
//        out_data_ready <= 1'b0;
        next_state <= STATE_COMPUTE;  
        startMont1_next <= 1'b0;
        startMont2_next <= 1'b0;
//        count_e_next <= count_e;
        case (CompState)
            Mont_idle: begin
                count_e_next  <= 11'd15;
                if (regDone) begin 
                    next_CompState<= Mont_idle; 
                    regDone_next <= 1'b1; 
                    end
                else begin 
                     next_CompState<= Mont_1st;   
                     regDone_next <= 1'b0; 
                     end 
            end
            Mont_1st: begin
                count_e_next  <= 11'd15;
                regDone_next <= 1'd0;
                if (doneMont1) begin 
                    next_CompState <= Mont_loop; 
                    startMont1_next <= 1'b1; 
                    startMont2_next <= 1'b1; end
                else begin
                    next_CompState <= Mont_1st; 
                    startMont1_next <= 1'b0; 
                    startMont2_next <= 1'b0; end
            end
            Mont_loop: begin
                regDone_next <= 1'd0;
                if (flag1 & flag2) begin
                    if (count_e > 5'd0)  next_CompState <= Mont_loop;
                    else next_CompState <= Mont_last; 
                    startMont1_next <= 1'b1; 
                    startMont2_next <= 1'b1;
                    count_e_next <= count_e - 1;
                    end
                else begin 
                    next_CompState <= Mont_loop; 
                    startMont1_next <= 1'b0; 
                    startMont2_next <= 1'b0; 
                    count_e_next <= count_e; end
            end
            Mont_last: begin
                startMont1_next <= 1'b0; 
                startMont2_next <= 1'b0;
                regDone_next <= 1'd0;
                count_e_next <= 11'd0;
                if (doneMont2) begin 
                    next_CompState <= Mont_idle; 
                    regDone_next <= 1'd1; 
                    next_state <= STATE_TX; end
                else next_CompState <= Mont_last; 
            end
//            default: next_CompState <= Mont_idle;         
        endcase
        
        
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_TX : begin
        next_state <= (~dma_idle) ? STATE_TX_WAIT : STATE_TX;
      end

      // Wait the completion of dma.
      STATE_TX_WAIT : begin
        next_state <= (dma_done) ? STATE_DONE : STATE_TX_WAIT;
      end

      // The command register might still be set to compute state. Hence, if
      // we go back immediately to the IDLE state, another computation will
      // start. We might go into a deadlock. So stay in this state, till CPU
      // sets the command to idle. While FPGA is in this state, it will
      // indicate the state with the status register, so that the CPU will know
      // FPGA is done with computation and waiting for the idle command.
      STATE_DONE : begin
        next_state <= (isCmdIdle) ? STATE_IDLE : STATE_DONE;
      end

    endcase
  end
    montgomery Mont1 (clk, resetn, startMont1, in_Mont1_1, in_Mont1_2, modulusN, resultMont1, doneMont1); 
    montgomery Mont2 (clk, resetn, startMont2, A, in_Mont2, modulusN, resultMont2, doneMont2); 
    
    always @(posedge clk)
    begin
        case (state) 
            STATE_RX_WAIT : 
                begin
                out_data_ready <= 1'b0; 
                if ( in_data_valid & in_param_valid & in_cmd_valid) begin
                    case (order_in)
                        3'd0:    modulusN  <= r_data; 
                        3'd1:     R_mod_N  <= r_data; 
                        3'd2:           x  <= r_data;   
                        3'd3:    R2_mod_N  <= r_data;    
                        3'd4:           e  <= r_data;     
                        default: begin  modulusN <= modulusN; R_mod_N <= R_mod_N; x <= x; 
                                        R2_mod_N <= R2_mod_N; e <= e; end
                    endcase
                out_data_ready <= 1'b1;
                end
                else begin  modulusN <= modulusN; R_mod_N <= R_mod_N; x <= x; 
                            R2_mod_N <= R2_mod_N; e <= e; end
                end
            
            default: begin
                out_data_ready <= 1'b0; 
                modulusN <= modulusN; R_mod_N <= R_mod_N; x <= x; 
                R2_mod_N <= R2_mod_N; e <= e;
            end
        endcase 
        
    end
    
    always@(*) 
    begin
        if (doneMont1)          flag1 <= 1'b1;
        else if (flag2_last)    flag1 <= 1'b0;
        else                    flag1 <= flag1_last;
        
        if (doneMont2)          flag2 <= 1'b1;
        else if (flag1_last)    flag2 <= 1'b0;
        else                    flag2 <= flag2_last;
    end
    
    always @(posedge clk)
    begin
        if (~resetn || startMont1) flag1_last <= 1'b0;
        else flag1_last <= flag1;
    end
    
    always @(posedge clk)
    begin
        if (~resetn || startMont2) flag2_last <= 1'b0;
        else flag2_last <= flag2;
    end
    
    always@(posedge clk) begin
    case (CompState)
        Mont_1st : begin sel1 = 2'd2;        sel_loop <= 1'd0;  sel_last <= 1'd0;  sel2 <= 1'd1;       end
        Mont_loop: begin sel1 = e[count_e];  sel_loop <= 1'd1;  sel_last <= 1'd0;  sel2 <= e[count_e]; end 
        Mont_last: begin sel1 = 2'd1;        sel_loop <= 1'd1;  sel_last <= 1'd1;  sel2 <= 1'd1;       end 
        default  : begin sel1 = 2'd2;        sel_loop <= 1'd0;  sel_last <= 1'd0;  sel2 <= 1'd0;       end
    endcase
    end
    
    always@(*) begin
        if (sel2) begin
            if (doneMont1) regx_D <= resultMont1;
            else           regx_D <= regx_Q; 
            if (doneMont2) regA_D <= resultMont2;
            else           regA_D <= regA_Q; 
        end
        else begin
            if (doneMont2) regx_D <= resultMont2;
            else           regx_D <= regx_Q; 
            if (doneMont1) regA_D <= resultMont1;
            else regA_D <= regA_Q; 
        end
    end
    
    always@(*) begin
        x_tilde <= regx_Q;
        if (sel_last)   in_Mont2 <= 1'd1;
        else            in_Mont2 <= x_tilde;
    end
    
    always@(*) begin
        case (sel1)
            2'd2:       begin in_Mont1_1 <= x;        in_Mont1_2 <= R2_mod_N; end
            2'd1:       begin in_Mont1_1 <= x_tilde;  in_Mont1_2 <= x_tilde;  end
            2'd0:       begin in_Mont1_1 <= A;        in_Mont1_2 <= A;        end
            default:    begin in_Mont1_1 <= x;        in_Mont1_2 <= R2_mod_N; end
        endcase
    end
    
    always@(*) begin
        if (sel_loop)   
            if (count_e==15) A <= R_mod_N; 
            else A <= regA_Q;
        else     A <= R_mod_N; 
    end
    
    always @(posedge clk)
    begin
        if (~resetn)   begin 
            order_in <= 1'b0;   
            out_param_ready <= 1'b0; end
        else if (in_param_valid)   begin
            order_in <= in_param_cnt;
            out_param_ready <= 1'b1;
            end
        else begin 
            order_in <= 1'b0;  
            out_param_ready <= 1'b0;
            end          
    end
    
//    always @(posedge clk)
//    begin
//        if (~resetn) begin
//            modulusN_last <= 1'b0;
//            R_mod_N_last  <= 1'b0;
//            x_last        <= 1'b0;
//            R2_mod_N_last <= 1'b0;
//            e_last        <= 1'b0;
//            end
//        else begin
//            modulusN_last <= modulusN;
//            R_mod_N_last  <= R_mod_N;
//            x_last        <= x;
//            R2_mod_N_last <= R2_mod_N;
//            e_last        <= e;
//            end
//    end
    
    always @(posedge clk)
    begin
        if (~resetn) begin 
            regx_Q      <= 1'd0; 
            regA_Q      <= 1'd0; 
            startMont1  <= 1'd0; 
            startMont2  <= 1'd0; 
            CompState   <= 1'd0; 
            count_e     <= 11'd15;  
            regDone     <= 1'd0; 
            end
        else begin
            regx_Q      <= regx_D;
            regA_Q      <= regA_D; 
            startMont1  <= startMont1_next; 
            startMont2  <= startMont2_next; 
            CompState   <= next_CompState; 
            count_e     <= count_e_next; 
            regDone     <= regDone_next; 
            end
    end
    

  always@(posedge clk) begin
    dma_rx_start <= 1'b0;
    dma_tx_start <= 1'b0;
    case (state)
      STATE_RX: dma_rx_start <= 1'b1;
      STATE_TX: dma_tx_start <= 1'b1;
    endcase
  end

  // Synchronous state transitions
  always@(posedge clk)
    state <= (~resetn) ? STATE_IDLE : next_state;


  // Here is a register for the computation. Sample the dma data inputr_data in
  // STATE_RX_WAIT. Update the data with a dummy operation in STATE_COMP.
  // In this example, the dummy operation sets most-significant 32-bit to zeros.
  // Use this register also for the data output.
//  reg [1023:0] r_data = 1024'h0;
//  reg [1023:0] r_data_tmp = 1024'h0;
  always@(posedge clk)
    case (state)
      STATE_RX_WAIT : r_data <= (dma_done) ? dma_rx_data : r_data;
      STATE_COMPUTE : r_data_tmp <= (regDone) ? regA_Q : r_data;
//      STATE_TX      : r_data <= (in_data_ready & dma_idle) ? r_data_tmp : r_data;   // TODO: out_data_ready
      STATE_TX_WAIT : r_data <= (in_data_ready & dma_idle) ? r_data_tmp : r_data;   // TODO: out_data_ready
      default : r_data <= (regDone) ? regA_Q : r_data;
    endcase
    assign dma_tx_data = r_data;


  // Status signals to the CPU
  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);
  wire isStateTxWait = (state == STATE_TX_WAIT || state == STATE_DONE);
  wire is_done     = (state == STATE_RX_WAIT || state == STATE_TX_WAIT || regDone || state == STATE_DONE);
  assign status = {out_cmd_ready, out_param_ready, command[`IN_PARAM_VALID_BIT], command[`IN_PARAM_CNT_BIT],4'b0000,command[`IN_DATA_READY_BIT],command[`IN_CMD_VALID_BIT], dma_isDone,is_done,out_data_ready,isStateTxWait,in_data_valid,command[`CMD_INSTR_BIT]};
//  assign status = {29'b0, dma_error, isStateIdle, isStateDone};

endmodule
