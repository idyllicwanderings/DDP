#include "common.h"
#include <stdalign.h>
#include <unistd.h>
#include <assert.h>
//#include "interface.h"
//#include "testvector.c"


// These variables are defined in the testvector.c
// that is created by the testvector generator python script
extern uint32_t N[32],    // modulus
                e[32],    // encryption exponent
                e_len,    // encryption exponent length
                d[32],    // decryption exponent
                d_len,    // decryption exponent length
                M[32],    // message
                R_N[32],  // 2^1024 mod N
                R2_N[32];// (2^1024)^2 mod N


#define DEBUG 1



#define CMD_INSTR_BIT           (uint32_t[]){2,0}
#define IN_DATA_VALID_BIT       3
#define OUT_TX_READY_BIT        4
#define OUT_DATA_READY_BIT      5
#define OUT_IS_DONE_BIT         6
#define IN_DONE_ACK_BIT         7
#define IN_CMD_VALID_BIT        8
#define IN_DATA_READY_BIT       9
//#define IN_PARAM_CNT_BIT       (uint32_t[]){12, 10}
//#define IN_PARAM_VALID_BIT      13
//#define OUT_PARAM_READY_BIT     14
//#define OUT_CMD_READY_BIT       15
#define IN_PARAM_CNT_BIT        (uint32_t[]){16, 14}
#define IN_PARAM_VALID_BIT      17
#define OUT_PARAM_READY_BIT     18
#define OUT_CMD_READY_BIT       19

#define CMD_IDLE          0
#define CMD_CMP           1
#define CMD_READ_IN       2
#define CMD_WRITE_OUT     3
#define CMD_ENCRYPT       4
#define CMD_DECRYPT       5



#define COMMAND 0
#define RXADDR  1
#define TXADDR  2
#define STATUS  0


#define PARAM_LEN 32
#define LONG_WAIT  300
#define CLK_PERIOD 10


#define ISFLAGSET(REG,BIT) ( (REG & (1<<BIT)) ? 1 : 0 )
#define BIT_M_TO_N(x, n,m)  ((uint32_t)(x << (31-(n))) >> ((31 - (n)) + (m)))
#define SET_BITS(x, bit1, bit2, data)  \
	(x =  ((uint32_t) ((x >> (bit1+1)) << (bit1+1)) \
			| (data << bit2) | ( (x << (32-bit2)) >> (32-bit2) )))        //TODO
#define GET_BIT(x, bit)    ((x & (1 << bit)) >> bit)
#define SET_BIT(x, bit, data)     ((uint32_t) ( \
								((x >> (bit+1)) << (bit+1)) \
								|  \
								(data << bit) \
								| \
								( (x << (32-bit)) >> (32-bit) ) \
								))

// Register file shared with FPGA
volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;


void print_array_contents(uint32_t* src) {
  int i;
  for (i=32-4; i>=0; i-=4)
    xil_printf("%08x %08x %08x %08x\n\r",
      src[i+3], src[i+2], src[i+1], src[i]);
}



uint32_t read_cmd_bit(uint32_t bit_idx) {
    return GET_BIT(HWreg[STATUS],bit_idx);
}


void write_cmd_bit(uint32_t bit_idx, uint32_t data) {
	uint32_t c = SET_BIT(HWreg[COMMAND], bit_idx, data);
    HWreg[COMMAND] = c;

}



void write_cmd_param_bits(uint32_t data)
{
    uint32_t cmd =  HWreg[COMMAND];
//    if (DEBUG) printf("before set cmd: status is %08x \r\n", cmd);
//    if (DEBUG) printf("BEFORE set REG: status is %08x \r\n", HWreg[COMMAND]);
	SET_BITS(cmd, IN_PARAM_CNT_BIT[0],IN_PARAM_CNT_BIT[1], data);
    HWreg[COMMAND] = cmd;

    write_cmd_bit(IN_PARAM_VALID_BIT,0b1);
    //if (DEBUG) printf("before set cmd: status is %08x \r\n", HWreg[COMMAND]);
    uint32_t out_param_ready;
    do {
        out_param_ready = read_cmd_bit(OUT_PARAM_READY_BIT);

    }   while (out_param_ready == 0b0);



}

void set_cmd(uint32_t cmd)
{

    uint32_t c=  HWreg[COMMAND];
    SET_BITS(c, CMD_INSTR_BIT[0],CMD_INSTR_BIT[1], cmd);
    HWreg[COMMAND] = c;

    write_cmd_bit(IN_CMD_VALID_BIT,0b1);

    uint32_t out_cmd_ready;
    do {
        out_cmd_ready = read_cmd_bit(OUT_CMD_READY_BIT);
    }   while (out_cmd_ready == 0b0);


}



void set_data(uint32_t* rx_addr, uint32_t* data, uint32_t data_len)
{
    for (uint32_t i = 0;i < data_len;i++) {
        rx_addr[i] = data[i];
    }

    write_cmd_bit(IN_DATA_VALID_BIT,0b1);
//    if (DEBUG) printf("status is %08x \r\n", HWreg[STATUS]);

    uint32_t out_data_ready;
    do {
        out_data_ready = read_cmd_bit(OUT_DATA_READY_BIT);
    }   while (out_data_ready == 0b0);

    write_cmd_bit(IN_CMD_VALID_BIT,0b0);
    write_cmd_bit(IN_PARAM_VALID_BIT,0b0);
    write_cmd_bit(IN_DATA_VALID_BIT,0b0);
//    if (DEBUG) printf("status is %08x \r\n", HWreg[STATUS]);
}



void dma_wait()
{
    uint32_t out_is_done;
    do {
        out_is_done = read_cmd_bit(OUT_IS_DONE_BIT);
//        printf("DMA: STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));


    } while (out_is_done == 0b0);

    // TODO: need to wait for cycles!
    write_cmd_bit(IN_DONE_ACK_BIT,0b1);
    write_cmd_bit(IN_DONE_ACK_BIT,0b0);
}




void read_data(uint32_t* data_addr)
{


    write_cmd_bit(IN_DATA_READY_BIT,0b1);
    uint32_t out_tx_ready;
    do {
        out_tx_ready = read_cmd_bit(OUT_TX_READY_BIT);
    } while (out_tx_ready == 0b0);

    // odata[] = ?
    // mem_read(MEM1_ADDR);         //TODO for MEM1_ADDR!

    write_cmd_bit(IN_DATA_READY_BIT,0b0);

}


int main() {

  init_platform();
  init_performance_counters(0);

  xil_printf("Begin\n\r");


  #define COMMAND 0
  #define RXADDR  1
  #define TXADDR  2
  #define STATUS  0

  // Aligned input and output memory shared with FPGA
  alignas(128) uint32_t idata[32]; //RX_ADDR_VALUE
  alignas(128) uint32_t odata[32]; //TX_ADDR_VALUE

  // Initialize odata to all zero's
  memset(odata,0,128);

  for (int i = 0; i < 32; i++) {
    idata[i] = i + 1;
  }

  HWreg[RXADDR] = (uint32_t)&idata; // store address idata in reg1
  HWreg[TXADDR] = (uint32_t)&odata; // store address odata in reg2



  printf("RXADDR %08X\r\n", (unsigned int)HWreg[RXADDR]);
  printf("TXADDR %08X\r\n", (unsigned int)HWreg[TXADDR]);

  printf("STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);
  printf("REG[3] %08X\r\n", (unsigned int)HWreg[3]);
  printf("REG[4] %08X\r\n", (unsigned int)HWreg[4]);

   //// --- Finish
  xil_printf("------------ ENCRYPTION: Started running... --------------------\n\r");


	//// --- Read inputs

	xil_printf("------------ ENCRYPTION: Read inputs --------------------\n\r");
START_TIMING

  write_cmd_param_bits((uint32_t)0);
xil_printf("------------ 1 --------------------\n\r");
  set_cmd(CMD_READ_IN);
  xil_printf("------------ 1-1 --------------------\n\r");
  set_data(idata, N, PARAM_LEN);
  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));

//  printf("\r\nI_Data:\r\n"); print_array_contents(idata);
  dma_wait();


  write_cmd_param_bits((uint32_t)1);
  set_cmd(CMD_READ_IN);
  set_data(idata, R_N, PARAM_LEN);
  xil_printf("------------ 2 --------------------\n\r");
  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));

//  printf("\r\nI_Data:\r\n"); print_array_contents(idata);
  dma_wait();

  write_cmd_param_bits((uint32_t)2);
  set_cmd(CMD_READ_IN);
  set_data(idata, M, PARAM_LEN);
  xil_printf("------------ 3--------------------\n\r");
  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));

//   printf("\r\nI_Data:\r\n"); print_array_contents(idata);
  dma_wait();

  write_cmd_param_bits((uint32_t)3);
  set_cmd(CMD_READ_IN);
  set_data(idata, R2_N, PARAM_LEN);
  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));

//  printf("\r\nI_Data:\r\n"); print_array_contents(idata);
  dma_wait();

  write_cmd_param_bits((uint32_t)4);
  set_cmd(CMD_READ_IN);
  set_data(idata, e, e_len);
  xil_printf("------------ 4--------------------\n\r");
  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));

  dma_wait();


STOP_TIMING


  //// --- Encryption
  xil_printf("------------ ENCRYPTION: Encryption started --------------------\n\r");
START_TIMING
	printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));

  set_cmd(CMD_ENCRYPT);
xil_printf("------------ 5--------------------\n\r");
	printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));


  dma_wait();
xil_printf("------------ 6--------------------\n\r");
STOP_TIMING



  //// --- Output
  xil_printf("------------ ENCRYPTION: Output data        --------------------\n\r");

START_TIMING

  set_cmd(CMD_WRITE_OUT);
  read_data(odata);
  dma_wait();

STOP_TIMING

 //// --- Finish
  xil_printf("------------ ENCRYPTION: Finished running!  --------------------\n\r");






  HWreg[COMMAND] = CMD_IDLE;

  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
  printf("STATUS 1 %08X\r\n", (unsigned int)HWreg[1]);
  printf("STATUS 2 %08X\r\n", (unsigned int)HWreg[2]);
  printf("STATUS 3 %08X\r\n", (unsigned int)HWreg[3]);
  printf("STATUS 4 %08X\r\n", (unsigned int)HWreg[4]);
  printf("STATUS 5 %08X\r\n", (unsigned int)HWreg[5]);
  printf("STATUS 6 %08X\r\n", (unsigned int)HWreg[6]);
  printf("STATUS 7 %08X\r\n", (unsigned int)HWreg[7]);

  printf("\r\nI_Data:\r\n"); print_array_contents(idata);
  printf("\r\nO_Data:\r\n"); print_array_contents(odata);


  // decryption
  
   //// --- Finish
  xil_printf("------------ DECRPTION: Started running... --------------------\n\r");


	//// --- Read inputs

	xil_printf("------------  DECRPTION: Read inputs --------------------\n\r");
START_TIMING

  write_cmd_param_bits((uint32_t)0);
  set_cmd(CMD_READ_IN);
  set_data(idata, N, PARAM_LEN);

  dma_wait();


  write_cmd_param_bits((uint32_t)1);
  set_cmd(CMD_READ_IN);
  set_data(idata, R_N, PARAM_LEN);
  dma_wait();

  write_cmd_param_bits((uint32_t)2);
  set_cmd(CMD_READ_IN);
  set_data(idata, M, PARAM_LEN);
  dma_wait();

  write_cmd_param_bits((uint32_t)3);
  set_cmd(CMD_READ_IN);
  set_data(idata, R2_N, PARAM_LEN);
  dma_wait();

  write_cmd_param_bits((uint32_t)4);
  set_cmd(CMD_READ_IN);
  set_data(idata, e, e_len);
  
  dma_wait();


STOP_TIMING


  xil_printf("------------  DECRPTION: computation started --------------------\n\r");
START_TIMING
	
  set_cmd(CMD_DECRYPT);
  dma_wait();

STOP_TIMING

  //// --- Output
  xil_printf("------------ DECRPTION: Output data        --------------------\n\r");

START_TIMING

  set_cmd(CMD_WRITE_OUT);
  read_data(odata);
  dma_wait();

STOP_TIMING

 //// --- Finish
  xil_printf("------------ DECRPTION: Finished running!  --------------------\n\r");



  // TEST
  
  assert();



  cleanup_platform();

  return 0;

}