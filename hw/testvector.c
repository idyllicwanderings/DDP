#include <stdint.h>                                              
#include <stdalign.h>                                            
                                                                 
// This file's content is created by the testvector generator    
// python script for seed = 2028                    
//                                                               
//  The variables are defined for the RSA                        
// encryption and decryption operations. And they are assigned   
// by the script for the generated testvector. Do not create a   
// new variable in this file.                                    
//                                                               
// When you are submitting your results, be careful to verify    
// the test vectors created for seeds from 2023.1, to 2023.5     
// To create them, run your script as:                           
//   $ python testvectors.py rsa 2023.1                          
                                                                 
// modulus                                                       
alignas(128) uint32_t N[32]       = {0xf3e68027, 0x07296b9d, 0xcb64d669, 0x7e5c1858, 0x6e7cb669, 0x3cb59080, 0xfe1f07dd, 0xe4fde5a5, 0x91637b15, 0x4368139f, 0x750a48c7, 0xf7fd405a, 0x84b32210, 0xf1980c37, 0xa957efa0, 0x4cad7593, 0xcd66cb72, 0x53e94159, 0x66337e2b, 0xabf3bb34, 0x23d6c272, 0x5515913c, 0x476cd07c, 0x5ed9aa86, 0x5c195377, 0xaa378cb6, 0xa66c78f8, 0xa5724348, 0x584677fe, 0xe776d501, 0x03d94ec0, 0xb8814294};           
                                                                              
// encryption exponent                                                        
alignas(128) uint32_t e[32]       = {0x0000ee63};            
alignas(128) uint32_t e_len       = 16;                                       
                                                                              
// decryption exponent, reduced to p and q                                    
alignas(128) uint32_t d[32]       = {0x49b0a08b, 0xb6656771, 0x8ea53732, 0x94b90e2b, 0x4a7159fa, 0x5a474c7a, 0xcdf986f4, 0x730bb19f, 0x960189b1, 0x33041852, 0x28faeaea, 0x194c9520, 0x291bffbb, 0xdda314d8, 0x02f2c848, 0x86952ab2, 0x740275f0, 0xca89c5f1, 0x150e24f5, 0xb5ee3882, 0x24c994c8, 0x24897baa, 0x320d7304, 0x9afb108a, 0x378e8eff, 0xcf45ebfb, 0x53a774ab, 0x5445e9e3, 0x8e1990d4, 0x1f87ac99, 0xcde70f2f, 0x044faf8b};           
alignas(128) uint32_t d_len       =  1019;    
                                                                              
// the message                                                                
alignas(128) uint32_t M[32]       = {0x89287b3e, 0xfb67f2e8, 0xc20f374a, 0x238cf16c, 0xd4f7df25, 0x9452c931, 0x98e3fb77, 0x6382acfd, 0x1670c6dc, 0x47b37a22, 0xcf69feda, 0x2a8e5f94, 0x98c540f6, 0xab7f7c8e, 0x16283c9f, 0xbf0afcf1, 0x710b2f1f, 0x51d94b2b, 0xe3a1544b, 0x063ac26c, 0x49f57676, 0x01a86b36, 0x158e8643, 0x374db26f, 0x578a610b, 0xdd640eaf, 0xfd34f74b, 0x6b173630, 0xa132818d, 0x632bd0ad, 0x16975272, 0xb48060b2};           
                                                                              
// R mod N, and R^2 mod N, (R = 2^1024)                                       
alignas(128) uint32_t R_N[32]     = {0x0c197fd9, 0xf8d69462, 0x349b2996, 0x81a3e7a7, 0x91834996, 0xc34a6f7f, 0x01e0f822, 0x1b021a5a, 0x6e9c84ea, 0xbc97ec60, 0x8af5b738, 0x0802bfa5, 0x7b4cddef, 0x0e67f3c8, 0x56a8105f, 0xb3528a6c, 0x3299348d, 0xac16bea6, 0x99cc81d4, 0x540c44cb, 0xdc293d8d, 0xaaea6ec3, 0xb8932f83, 0xa1265579, 0xa3e6ac88, 0x55c87349, 0x59938707, 0x5a8dbcb7, 0xa7b98801, 0x18892afe, 0xfc26b13f, 0x477ebd6b};        
alignas(128) uint32_t R2_N[32]    = {0x47a79864, 0xb4628640, 0x6b26a9b1, 0x9524a4fa, 0x3030ea2f, 0xfe3ba8dd, 0xf6ae6e4c, 0xb02ef5fc, 0x88d42a48, 0x78f12200, 0x62198b6d, 0xf83778a5, 0x6e64e6f3, 0x9092a587, 0x8ea557fb, 0x91e9b4e6, 0x075b7337, 0xcd4f6167, 0x46dbaef7, 0xa1f3b5a6, 0xc179bcc6, 0x2cc6466e, 0x2dce0c47, 0x0a191d8e, 0x8b0e7860, 0xde9448e6, 0xde36bd71, 0x9c95d4f0, 0xcb73600b, 0x3cd47d17, 0xf5a26798, 0x3965165c};        

