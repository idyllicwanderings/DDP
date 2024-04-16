`timescale 1ns / 1ps

module rsa_wrapper
(
    // The clock and active low reset
    input           clk,
    input           resetn,
    
    input  [  31:0] arm_to_fpga_cmd,
    input           arm_to_fpga_cmd_valid,
    output          fpga_to_arm_done,
    input           fpga_to_arm_done_read,

    input           arm_to_fpga_data_valid,
    output          arm_to_fpga_data_ready,
    input  [1023:0] arm_to_fpga_data,
    
    output          fpga_to_arm_data_valid,
    input           fpga_to_arm_data_ready,
    output [1023:0] fpga_to_arm_data,
    
    output [   3:0] leds);

    ////////////// - State Machine 

    /// - State Machine Parameters

    localparam STATE_BITS           = 3;    
    localparam STATE_WAIT_FOR_CMD   = 3'h0;  
    localparam STATE_READ_DATA      = 3'h1;
    localparam STATE_COMPUTE        = 3'h2;
    localparam STATE_ENCRYPT        = 3'h3;
    localparam STATE_DECRYPT        = 3'h4;
    localparam STATE_WRITE_DATA     = 3'h5;
    localparam STATE_ASSERT_DONE    = 3'h6;
    localparam STATE_WAIT_FOR_RESULT= 3'h7;
    

    reg [STATE_BITS-1:0] r_state;
    reg [STATE_BITS-1:0] next_state;
    
    localparam CMD_READ             = 32'h0;
    localparam CMD_ENCRYPT          = 32'h1;    
    localparam CMD_WRITE            = 32'h2;
    localparam CMD_DECRYPT          = 32'h3;

    wire calc_done;
    /// - State Transition

    always @(*)
    begin
        if (resetn==1'b0)
        begin
            next_state <= STATE_WAIT_FOR_CMD;
        end
        else
        begin
            case (r_state)
                STATE_WAIT_FOR_CMD:
                    begin
                        if (arm_to_fpga_cmd_valid) begin
                            case (arm_to_fpga_cmd)
                                CMD_READ:
                                begin
                                    next_state <= STATE_READ_DATA;
                                end
                                CMD_ENCRYPT:
                                begin                      
                                    next_state <= STATE_ENCRYPT;
                                end
                                CMD_DECRYPT:
                                begin
                                    next_state <= STATE_DECRYPT;
                                end
                                CMD_WRITE:
                                begin
                                    next_state <= STATE_WRITE_DATA;
                                end
                                default:
                                    next_state <= r_state;
                            endcase
                        end else begin
                            next_state <= r_state;
                        end
                    end

                STATE_READ_DATA:
                    next_state <= (arm_to_fpga_data_valid) ? STATE_ASSERT_DONE : r_state;
                
                STATE_ENCRYPT:
                    next_state <= STATE_COMPUTE;
                
                STATE_DECRYPT:
                    next_state <= STATE_COMPUTE;

                STATE_COMPUTE:
                    next_state <= STATE_WAIT_FOR_RESULT;
                
                STATE_WAIT_FOR_RESULT:
                    next_state <= (calc_done) ? STATE_ASSERT_DONE : STATE_WAIT_FOR_RESULT;

                STATE_WRITE_DATA:
                begin
                    next_state <= (fpga_to_arm_data_ready) ? STATE_ASSERT_DONE : r_state;
                end
                STATE_ASSERT_DONE:
                begin
                    next_state <= (fpga_to_arm_done_read) ? STATE_WAIT_FOR_CMD : r_state;
                end

                default:
                    next_state <= STATE_WAIT_FOR_CMD;

            endcase
        end
    end

    /// - Synchronous State Update

    always @(posedge(clk))
        if (resetn==1'b0)
            r_state <= STATE_WAIT_FOR_CMD;
        else
            r_state <= next_state;   

    ////////////// - Computation

    reg [1023:0] core_data;

    reg start;
    reg encrpyt_mode;
    reg exp_resetn;

    wire [1023:0] result;

    reg  [1023:0]   msg;
    reg  [1023:0]   exp;
    reg  [1023:0]   n;
    reg  [1023:0]   rmodn;
    reg  [1023:0]   r2modn;

    montgomery_exp mont_exp(
        .clk(clk),
        .resetn(exp_resetn),
        .start(start),
        .encryp_mode(encrpyt_mode),
        .msg(msg),
        .exp(exp),
        .n(n),
        .rmodn(rmodn),
        .r2modn(r2modn),
        .result(result),
        .done(calc_done)
    );
    
    reg[2:0] param_cnt;

    always @(posedge(clk))
        if (resetn==1'b0)
        begin
            core_data <= 1024'b0;
            param_cnt <= 0;
            exp_resetn <= 1'b0;
        end
        else
        begin
            case (r_state)
                STATE_READ_DATA: begin
                    exp_resetn <= 1'b0;
                    if (arm_to_fpga_data_valid)
                    begin
                        case (param_cnt)
                            3'b000:
                            begin
                                msg <= arm_to_fpga_data;
                                param_cnt <= 3'b001;
                            end
                            3'b001:
                            begin
                                exp <= arm_to_fpga_data;
                                param_cnt <= 3'b010;
                            end
                            3'b010:
                            begin
                                n <= arm_to_fpga_data;
                                param_cnt <= 3'b011;
                            end
                            3'b011:
                            begin
                                rmodn <= arm_to_fpga_data;
                                param_cnt <= 3'b100;
                            end
                            3'b100:
                            begin
                                r2modn <= arm_to_fpga_data;
                                param_cnt <= 3'b000;
                            end
                            default: param_cnt <= 3'b000;
                        endcase
                    end
                    else
                    begin
                        msg <= msg;
                        exp <= exp;
                        n <= n;
                        rmodn <= rmodn;
                        r2modn <= r2modn;
                    end
                end

                STATE_ENCRYPT: begin
                    exp_resetn <= 1'b0;
                    encrpyt_mode <= 1'b0;
                end

                STATE_DECRYPT: begin
                    exp_resetn <= 1'b0;
                    encrpyt_mode <= 1'b1;
                end
                
                STATE_COMPUTE:
                begin
                    start <= 1'b1;
                    exp_resetn <= 1'b1;
                end
                
                default: begin
                    msg <= msg;
                    exp <= exp;
                    n <= n;
                    rmodn <= rmodn;
                    r2modn <= r2modn;
                    start <= 1'b0;
                end
            endcase
        end
    
    assign fpga_to_arm_data       = result;

    ////////////// - Valid signals for notifying that the computation is done

    /// - Port handshake

    reg r_fpga_to_arm_data_valid;
    reg r_arm_to_fpga_data_ready;

    always @(posedge(clk)) begin
        r_fpga_to_arm_data_valid = (r_state==STATE_WRITE_DATA);
        r_arm_to_fpga_data_ready = (r_state==STATE_READ_DATA);
    end
    
    assign fpga_to_arm_data_valid = r_fpga_to_arm_data_valid;
    assign arm_to_fpga_data_ready = r_arm_to_fpga_data_ready;
    
    /// - Done signal
    
    reg r_fpga_to_arm_done;

    always @(posedge(clk))
    begin
        r_fpga_to_arm_done <= (r_state==STATE_ASSERT_DONE);
    end

    assign fpga_to_arm_done = r_fpga_to_arm_done;
    
    ////////////// - Debugging signals
    
    // The four LEDs on the board are used as debug signals.
    // Here they are used to check the state transition.

    assign leds             = {1'b0, r_state};

endmodule