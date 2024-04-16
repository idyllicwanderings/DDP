`timescale 1ns / 1ps

`define HUGE_WAIT   300
`define LONG_WAIT   100
`define RESET_TIME   25
`define CLK_PERIOD   10
`define CLK_HALF      5


`define CMD_INSTR_BIT           2:0
`define IN_DATA_VALID_BIT       3
`define OUT_TX_READY_BIT        4
`define OUT_DATA_READY_BIT      5
`define OUT_IS_DONE_BIT         6
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



module tb_rsa_wrapper();
    
  reg           clk         ;
  reg           resetn      ;
  wire          leds        ;

  reg  [16:0]   mem_addr    = 'b0 ;
  reg  [1023:0] mem_din     = 'b0 ;
  wire [1023:0] mem_dout    ;
  reg  [127:0]  mem_we      = 'b0 ;

  reg  [ 11:0] axil_araddr  ;
  wire         axil_arready ;
  reg          axil_arvalid ;
  reg  [ 11:0] axil_awaddr  ;
  wire         axil_awready ;
  reg          axil_awvalid ;
  reg          axil_bready  ;
  wire [  1:0] axil_bresp   ;
  wire         axil_bvalid  ;
  wire [ 31:0] axil_rdata   ;
  reg          axil_rready  ;
  wire [  1:0] axil_rresp   ;
  wire         axil_rvalid  ;
  reg  [ 31:0] axil_wdata   ;
  wire         axil_wready  ;
  reg  [  3:0] axil_wstrb   ;
  reg          axil_wvalid  ;
  
  // My code        

  reg in_data_valid, in_cmd_valid, out_tx_ready;
  reg out_data_ready, in_done_ack, out_param_ready, out_cmd_ready;
  reg out_is_done;
  reg [31:0] reg_status;

      
  tb_rsa_project_wrapper dut (
    .clk                 ( clk           ),
    .leds                ( leds          ),
    .resetn              ( resetn        ),
    .s_axi_csrs_araddr   ( axil_araddr   ),
    .s_axi_csrs_arready  ( axil_arready  ),
    .s_axi_csrs_arvalid  ( axil_arvalid  ),
    .s_axi_csrs_awaddr   ( axil_awaddr   ),
    .s_axi_csrs_awready  ( axil_awready  ),
    .s_axi_csrs_awvalid  ( axil_awvalid  ),
    .s_axi_csrs_bready   ( axil_bready   ),
    .s_axi_csrs_bresp    ( axil_bresp    ),
    .s_axi_csrs_bvalid   ( axil_bvalid   ),
    .s_axi_csrs_rdata    ( axil_rdata    ),
    .s_axi_csrs_rready   ( axil_rready   ),
    .s_axi_csrs_rresp    ( axil_rresp    ),
    .s_axi_csrs_rvalid   ( axil_rvalid   ),
    .s_axi_csrs_wdata    ( axil_wdata    ),
    .s_axi_csrs_wready   ( axil_wready   ),
    .s_axi_csrs_wstrb    ( axil_wstrb    ),
    .s_axi_csrs_wvalid   ( axil_wvalid   ),
    .mem_clk             ( clk           ), 
    .mem_addr            ( mem_addr      ),     
    .mem_din             ( mem_din       ), 
    .mem_dout            ( mem_dout      ), 
    .mem_en              ( 1'b1          ), 
    .mem_rst             (~resetn        ), 
    .mem_we              ( mem_we        ));
      
  // Generate Clock
  initial begin
      clk = 0;
      forever #`CLK_HALF clk = ~clk;
  end

  // Initialize signals to zero
  initial begin
    axil_araddr  <= 'b0;
    axil_arvalid <= 'b0;
    axil_awaddr  <= 'b0;
    axil_awvalid <= 'b0;
    axil_bready  <= 'b0;
    axil_rready  <= 'b0;
    axil_wdata   <= 'b0;
    axil_wstrb   <= 'b0;
    axil_wvalid  <= 'b0;
            
    //My code
    in_data_valid   <= 'b0;
    in_cmd_valid    <= 'b0;
    out_data_ready  <= 'b0;
    out_tx_ready    <= 'b0;
    in_done_ack     <=   'b0;
    out_is_done     <=   'b0;
    out_param_ready <=   'b0;
    out_cmd_ready   <=   'b0;
    reg_status      <= 32'b0;
  end

  // Reset the circuit
  initial begin
      resetn = 0;
      #`RESET_TIME
      resetn = 1;
  end

  // Read from specified register
  task reg_read;
    input [11:0] reg_address;
    output [31:0] reg_data;
    begin
      // Channel AR
      axil_araddr  <= reg_address;
      axil_arvalid <= 1'b1;
      wait (axil_arready);
      #`CLK_PERIOD;
      axil_arvalid <= 1'b0;
      // Channel R
      axil_rready  <= 1'b1;
      wait (axil_rvalid);
      reg_data <= axil_rdata;
      #`CLK_PERIOD;
      axil_rready  <= 1'b0;
      $display("reg[%x] <= %x", reg_address, reg_data);
      #`CLK_PERIOD;
      #`RESET_TIME;
    end
  endtask

  // Write to specified register
  task reg_write;
    input [11:0] reg_address;
    input [31:0] reg_data;
    begin
      // Channel AW
      axil_awaddr <= reg_address;
      axil_awvalid <= 1'b1;
      // Channel W
      axil_wdata  <= reg_data;
      axil_wstrb  <= 4'b1111;
      axil_wvalid <= 1'b1;
      // Channel AW
      wait (axil_awready);
      #`CLK_PERIOD;
      axil_awvalid <= 1'b0;
      // Channel W
      wait (axil_wready);
      #`CLK_PERIOD;
      axil_wvalid <= 1'b0;
      // Channel B
      axil_bready <= 1'b1;
      wait (axil_bvalid);
      #`CLK_PERIOD;
      axil_bready <= 1'b0;
      $display("reg[%x] <= %x", reg_address, reg_data);
      #`CLK_PERIOD;
      #`RESET_TIME;
    end
  endtask

  // Read at given address in memory
  task mem_write;
    input [  16:0] address;
    input [1024:0] data;
    begin
      mem_addr <= address;
      mem_din  <= data;
      mem_we   <= {128{1'b1}};
      #`CLK_PERIOD;
      mem_we   <= {128{1'b0}};
      $display("mem[%x] <= %x", address, data);
      #`CLK_PERIOD;
    end
  endtask

  // Write to given address in memory
  task mem_read;
    input [  16:0] address;
    begin
      mem_addr <= address;
      #`CLK_PERIOD;
      $display("mem[%x] => %x", address, mem_dout);
    end
  endtask
  
//  task wait;
//    input bit
//    begin
//        while (bit)
//    end
//   endtask

    // -----------------------------------------------------------------------------------------------------------------------------------------------

  // Byte Addresses of 32-bit registers
  localparam  COMMAND = 0, // r0
              RXADDR  = 4, // r1
              TXADDR  = 8, // r2
              STATUS  = 0;

  // Byte Addresses of 1024-bit distant memory locations
  localparam  MEM0_ADDR  = 16'h00,
              MEM1_ADDR  = 16'h80;

//      reg [31:0] reg_status;
      
      wire [1023:0] N = 1024'h8ccd1dfb6b7f37a6ad7b3a5537be7edfa3e6542a5a163defd2e2eb0df705b3117ea0471532ad930eaba7f17d0574e21140ff72c7ffe499bbf9f553b91bd52540e3f33e96de62925a16a89be948d4491c943749c833956b1ccec7727f9883fb26710911ff014a5af43aa36139d2aa599eb14bdf5a43fde98671b05f855a163619;
            
      wire [1023:0] RmodN = 1024'h7332e2049480c8595284c5aac84181205c19abd5a5e9c2102d1d14f208fa4cee815fb8eacd526cf154580e82fa8b1deebf008d38001b6644060aac46e42adabf1c0cc169219d6da5e9576416b72bb6e36bc8b637cc6a94e331388d80677c04d98ef6ee00feb5a50bc55c9ec62d55a6614eb420a5bc0216798e4fa07aa5e9c9e7;
            
      wire [1023:0] m  = 1024'h883e80f8d32b319299e45e359a2aa5abb8d5fa30ddd81eb4158349a5261cb35499706945a09c5fe481d0273e5f02f5e056a3f822e80aefd453d8f5b83e23207c36fbe9634b534fad56d501b5cb48b9878fef5c39a90a8f69aca88fbd3f6b86b217ec2f30e7164e573a2cafc216b804955042194211f9025e1df902743060afe7;
            
      wire [1023:0] R2modN  = 1024'h794229e15b7db804185b941965fdc73393a9aa0bfb374d492cfd0515d8834a2f4df5cdf10e6511fb29487f9e59af0052a0ca9ead660f933b2357f142c5069a6869c916e01a2242a45249155e0e96468f0974a0321bfddba8f3b853e137a348bbeb2b37e9202e1c371518ef63c105453d4463ace609b1a6939abe234c307db791;
            
      wire [1023:0] e = 1024'h98c9;
        
        
    // 3 bit instruction
    localparam CMD_IDLE             = 32'h0;
    localparam CMD_COMP             = 32'h1;
    localparam CMD_READ_IN          = 32'h2;
    localparam CMD_WRITE_OUT        = 32'h3;
    localparam CMD_ENCRYPT          = 32'h4;
    localparam CMD_DECRYPT          = 32'h5;
    
    

      // --------------------------------[WRITE] TO A CONTROL BIT IN [COMMAND]----------------------------------------------------------------------------------------------------
  task write_cmd_bit;
    input [31:0] bit_index;
    input data_bit;
    begin
        //reg_read(COMMAND,reg_status);
        $display("[DEBUG]: writing to indx %x with data_bit %x",bit_index,data_bit);
        reg_status[bit_index] <= data_bit;
        #`CLK_PERIOD;
        reg_write(COMMAND,reg_status);
    end
  endtask
  
   task write_cmd_param_bits;
    input [2:0] data_bit;
    begin
        reg_status[`IN_PARAM_CNT_BIT] <= data_bit;
        #`CLK_PERIOD;
        reg_write(COMMAND,reg_status);
        
        write_cmd_bit(`IN_PARAM_VALID_BIT,'b1);
        read_cmd_bit(`OUT_PARAM_READY_BIT,out_param_ready);
            while (out_param_ready == 1'b0)
                begin
                    #`LONG_WAIT;
                   read_cmd_bit(`OUT_PARAM_READY_BIT,out_param_ready);
                end
//        write_cmd_bit(`IN_PARAM_VALID_BIT,'b0);   
        #`CLK_PERIOD;
        
    end
  endtask
  
    // ---------------------------------[READ] FROM A CONTROL BIT IN [COMMAND]-------------------------------------------------------------
   task read_cmd_bit;
    input [31:0] bit_index;
    output data;
    begin
        reg_read(COMMAND,reg_status);
        data <= reg_status[bit_index];
        #`CLK_PERIOD;
    end
  endtask
  
   // -----------------------------------[WRITE] TO CMD INSTRS IN [COMMAND]------------------------------
  task write_cmd_instr;
    input [31:0] data_bit;
    begin
        $display("[DEBUG]: entered write_cmd_ins 1");
        reg_status <= {reg_status[31:3], data_bit[2:0]};
        #`CLK_PERIOD;
        reg_write(COMMAND,reg_status);
    end
  endtask
  
   // ------------------------------------[WRITE] CMD TO FGPA -----------------------------------------------------------
  
  task set_cmd;
    input [2:0] INSTR;                                 //3-Sbit
    begin
                       //instr: the constant values of CMD instructions
        write_cmd_instr(INSTR);
        
        write_cmd_bit(`IN_CMD_VALID_BIT,'b1);

        $display("[DEBUG]: writing to indx %x ",`IN_CMD_VALID_BIT);

        read_cmd_bit(`OUT_CMD_READY_BIT,out_cmd_ready);
            while (out_cmd_ready == 1'b0)
                begin
                    #`LONG_WAIT;
                   read_cmd_bit(`OUT_CMD_READY_BIT,out_cmd_ready);
                end
//        write_cmd_bit(`IN_CMD_VALID_BIT,'b0);   
        #`CLK_PERIOD;

    end
    endtask

    // -------------------------------------[WRITE] DATA TO FGPA----------------------------------------------------------
    task set_data;                             
        input [1023:0] data;
        begin
            mem_write(MEM0_ADDR, data);                     // dma_address: the address share the data to and from fpga
                                                            // TODO: HOW TO ENSURE FPGA READS FROM THIS ADDR
//            reg_write(RXADDR, MEM0_ADDR);
            
            //in_data_valid <= 1'b1;
            write_cmd_bit(`IN_DATA_VALID_BIT,'b1);
//            #`CLK_PERIOD;
            read_cmd_bit(`OUT_DATA_READY_BIT,out_data_ready);
            while (out_data_ready == 1'b0)
                begin
                    #`LONG_WAIT;
                   read_cmd_bit(`OUT_DATA_READY_BIT,out_data_ready);
                end
            //wait(out_data_ready == 1'b1);
            //in_data_valid <= 1'b0;
            write_cmd_bit(`IN_CMD_VALID_BIT,'b0);
            write_cmd_bit(`IN_PARAM_VALID_BIT,'b0);   
            write_cmd_bit(`IN_DATA_VALID_BIT,'b0);   
            #`CLK_PERIOD;
        end
    endtask

    // ---------------------------------------[READ] CMD TO FGPA-------------------------------------------------------
    task read_data;
    begin
        //out_data_ready <= 1'b1;
        //#`CLK_PERIOD;
        //wait(dma_tx_start == 1'b1);
        //#`CLK_PERIOD;
        // mem_read(MEM1_ADDR);                            // TODO: ENSURE DMA WRITE OUTS TO TX ADDR
        //out_data_ready <= 1'b0;
        //#`CLK_PERIOD;
//        reg_write(TXADDR, MEM1_ADDR);
        
        write_cmd_bit(`IN_DATA_READY_BIT,'b1); 
        #`CLK_PERIOD;
        
        read_cmd_bit(`OUT_TX_READY_BIT,out_tx_ready);
            while (out_tx_ready == 1'b0)
                begin
                    #`LONG_WAIT;
                   read_cmd_bit(`OUT_TX_READY_BIT,out_tx_ready);
                end
                 
                
        #`CLK_PERIOD;
//        reg_write(TXADDR, MEM1_ADDR);
        mem_read(MEM1_ADDR);                            // TODO: ENSURE DMA WRITE OUTS TO TX ADDR
        write_cmd_bit(`IN_DATA_READY_BIT,'b0); 
        #`CLK_PERIOD;
    end
    endtask


    // ----------------------------------------WAIT FOR ACK-----------------------------------------------------
    task dma_wait;
    begin
        read_cmd_bit(`OUT_IS_DONE_BIT,out_is_done);
            while (out_is_done == 1'b0)
                begin
                    #`LONG_WAIT;
                   read_cmd_bit(`OUT_IS_DONE_BIT,out_is_done);
                end
        
         write_cmd_bit(`IN_DONE_ACK_BIT,'b1);    
         #`CLK_PERIOD;
         write_cmd_bit(`IN_DONE_ACK_BIT,'b0); 
         #`CLK_PERIOD;        
//        wait(out_is_done == 1'b1);
//         in_done_ack <= 1'b1;
//        #`CLK_PERIOD;
//         in_done_ack <= 1'b0;
//         #`CLK_PERIOD;
    end 
    endtask



    initial begin

        #`LONG_WAIT
        
        ///////////////////// ENCRYPTION  /////////////////////
        
        ///////////////////// Multiple input data to FPGA
//        reg_write(RXADDR, MEM0_ADDR);
//        reg_write(TXADDR, MEM1_ADDR);
        
        $display("---  Input Parsing STARTs --- ");
        reg_write(RXADDR, MEM0_ADDR);
        reg_write(TXADDR, MEM1_ADDR);
//        set_cmd(CMD_IDLE);
        
//        set_cmd(CMD_COMP);
        write_cmd_param_bits(3'd0);
        set_cmd(CMD_READ_IN);
        set_data(N);
        dma_wait();

        write_cmd_param_bits(3'd1);
        set_cmd(CMD_READ_IN);
        set_data(RmodN);
        dma_wait();

        write_cmd_param_bits(3'd2);
        set_cmd(CMD_READ_IN);
        set_data(m);
        dma_wait();

        write_cmd_param_bits(3'd3);
        set_cmd(CMD_READ_IN);
        set_data(R2modN);
        dma_wait();

        write_cmd_param_bits(3'd4);
        set_cmd(CMD_READ_IN);
        set_data(e);
        dma_wait();

        /////////////////////  Perform the compute operation
        $display("--- Computatio of RSA --- ");
        set_cmd(CMD_ENCRYPT);
        dma_wait();


	    ///////////////////// Obtain compute results
        
        $display("--- Output results --- ");
        set_cmd(CMD_WRITE_OUT);
        read_data();
        dma_wait();
        $finish;

    end
endmodule



////    #`LONG_WAIT

////    mem_write(MEM0_ADDR, 1024'd1);
////    mem_write(MEM1_ADDR, 1024'd2);

////    reg_write(RXADDR, MEM0_ADDR);
////    reg_write(TXADDR, MEM1_ADDR);

////    reg_write(COMMAND, 32'h00000001);
    
////    // Poll Done Signal
////    reg_read(COMMAND, reg_status);
////    while (reg_status[0]==1'b0)
////    begin
////      #`LONG_WAIT;
////      reg_read(COMMAND, reg_status);
////    end
    
////    reg_write(COMMAND, 32'h00000000);

////    mem_read(MEM1_ADDR);

////    $finish;

//  end
//endmodule