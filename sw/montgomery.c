/*
 * montgomery.c
 *
 */
// todo: uncommment the lines when submitting
#include "montgomery.h"

#include <stdint.h>
#include <stdbool.h>
#define DEBUG 0

typedef uint32_t u32;
typedef uint64_t u64;


u32 term_mult(u32 *x, u32 y) { // do inline of this function
    return x[0] * y;
}


// a and b size can be different!
uint8_t mp_compare1(uint32_t *a, uint32_t *b, uint32_t size, bool carry_a) {
	if (carry_a) return 1;
	uint32_t i = size -1;
    while (i >= 0) {
        if (a[i] > b[i]) return 1;
        else if (a[i] < b[i]) return 0;
        else i--;
    }
    return 1;
}


//TODO: modify n to a 32-bit while a is a 33-bit results!
// TODO: verify its correctness
void sub_condition(u32 *a, u32 *n,u32 size) { 
    if (mp_compare1(a,n,size,false)) {
        mp_sub_same(a,n,size);
    }
}


// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// CHIOS implementation
void montMul(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime,\
 uint32_t *res, uint32_t size)
{
    u32 carry; 
    u64 sum;
    u32 t[34];

    for (u32 i = 0; i <= size + 1; i++) { 
        //optimisation TODO
        t[i] = 0x0;
    }

    for (u32 i = 0; i < size; i++) { 
        // 1. loop unrolling: all? step = 4？
        carry = 0;
        for (u32 j = 0; j < size - i; j++) {
            sum = t[i + j] +  (u64)a[j] * b[i] + carry;
            // TODO: what to do with the optimisation of use of 64 bits integer
            carry =  sum >> 32;
            // 
            t[i + j] = sum;
        }
        sum = (u64)t[size] + carry;
        carry = sum >> 32;
        t[size] = sum;
        t[size + 1] += carry;
    }

    //but it is correct to not equal to the a \mul b, 
    //which is double size bigger

    for (int i = 0; i < size; i++) {

   
        u32 m = term_mult(n_prime,t[0]);  // inline for term_mult
        sum = t[0] + (u64)m * n[0];
        carry = (sum >> 32); 

        for (int j = 1; j < size; j++) {
            sum = t[j] + (u64)m * n[j] + carry;
            carry = sum >> 32;
            t[j - 1] = sum;
        }

        sum = (u64)t[size] + carry;
        carry = sum >> 32;
        t[size - 1] = sum;
        t[size] = t[size + 1] + carry;
        t[size + 1]  = 0;

        for (int j = i + 1; j < size; j++) {
            sum = t[size - 1] + (u64)b[j] * a[size - j + i];
            carry = sum >> 32;

            t[size - 1] = sum;
            sum = (u64)t[size] + carry;
            carry = sum >> 32;
            t[size] = sum;
            t[size + 1] += carry;
        }

    }

    sub_condition(t,n,size);

    for (u32 i = 0; i < size; i++) {
        res[i] = t[i];
    }

}




// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// Optimised ASM version
void montMulOpt(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size)
{
    u32 carry;
    u64 sum;
    u32 t[34];
    
    init(t);

//    for (u32 i = 0; i <= size + 1; i++) { 
//        //optimisation TODO
//        t[i] = 0x0;
//    }
//    
     mult(a,b,t,size);


//    for (u32 i = 0; i < size; i++) {
//        carry = 0;
//        for (u32 j = 0; j < size - i; j++) {
//            sum = t[i + j] +  (u64)a[j] * b[i] + carry;
//            // TODO: what to do with the optimisation of use of 64 bits integer
//            carry =  sum >> 32;
//            //
//            t[i + j] = sum;
//        }
//        sum = (u64)t[size] + carry;
//        carry = sum >> 32;
//        t[size] = sum;
//        t[size + 1] += carry;
//    }

   
    reduct(a,b,n,n_prime,t,size);

//    for (int i = 0; i < size; i++) {
//
//
//        u32 m = term_mult(n_prime,t[0]);  // inline for term_mult
//        sum = t[0] + (u64)m * n[0];
//        carry = (sum >> 32);
//
//        for (int j = 1; j < size; j++) {
//            sum = t[j] + (u64)m * n[j] + carry;
//            carry = sum >> 32;
//            t[j - 1] = sum;
//        }
//
//        sum = (u64)t[size] + carry;
//        carry = sum >> 32;
//        t[size - 1] = sum;
//        t[size] = t[size + 1] + carry;
//        t[size + 1]  = 0;
//
//        for (int j = i + 1; j < size; j++) {
//            sum = t[size - 1] + (u64)b[j] * a[size - j + i];
//            carry = sum >> 32;
//
//            t[size - 1] = sum;
//            sum = (u64)t[size] + carry;
//            carry = sum >> 32;
//            t[size] = sum;
//            t[size + 1] += carry;
//        }
//
//    }

    condsub(t,n,size);
    //sub_condition(t,n,size);

    arr_copy(t,res);

}





