/*
 * mp_arith.c
 *
 */

#include <stdint.h>
#include <stdbool.h>


typedef uint32_t u32;
typedef uint64_t u64;

// a and b size can be different!
uint8_t mp_compare(uint32_t *a, uint32_t *b, uint32_t size, bool carry_a) {
	if (carry_a) return 1;
	uint32_t i = size -1;
    while (i >= 0) {
        if (a[i] > b[i]) return 1;
        else if (a[i] < b[i]) return 0;
        else i--;
    }
    return 1;
}

void mp_duplicate(uint32_t *frm, uint32_t *to,uint32_t size) {
	 for (uint32_t i = 0; i < size; i++) {
	        to[i] = frm[i];
	    }
}

// Calculates res = a + b.
// a and b represent large integers stored in uint32_t arrays
// a and b are arrays of size elements, res has size+1 elements

// 3056 cycle
void mp_add(uint32_t *a, uint32_t *b, uint32_t *res, uint32_t size)
{
	uint64_t carry = 0;
    for (uint32_t i = 0; i < size;i++) {
        res[i] = (a[i] + b[i] + carry);
        carry = (((uint64_t)a[i] + b[i] + carry) >> 32);
    }
    res[size] = carry;
}

//@ overload
void mp_add_same(uint32_t *a, uint32_t *res, uint32_t size)
{
	uint64_t carry = 0;
    for (uint32_t i = 0; i < size;i++) {
        u32 tmp = (a[i] + res[i] + carry);
        carry = (((uint64_t)a[i] + res[i] + carry) >> 32);
        a[i] = tmp;
    }
    res[size] = carry;
}

// Calculates res = a - b.
// a and b represent large integers stored in uint32_t arrays
// a, b and res are arrays of size elements
void mp_sub(uint32_t *a, uint32_t *b, uint32_t *res, uint32_t size)
{
    int64_t carry = 0;
	for(uint32_t i = 0; i < size; ++ i){
		res[i] = a[i] - b[i] + carry;
        carry =  ((int64_t)a[i] - (int64_t)b[i] + carry >= 0) - 1;
		// keep it like : uint32_t carry1 = t1 +1 -t2 >0; instead of t1 +1 > t2 in order to prevent overflow
		//if (DEBUG && i == 31 ) xil_printf("carry%d is %u with sub= %u \n",i,carry,a[i]-b[i]+1);
	} 

}

// @overload
// C doesn;t have function overloading!
void mp_sub_same(uint32_t *a, uint32_t *res, uint32_t size)
{
    int64_t carry = 0;
	for(u32 i = 0; i < size; ++ i){
		u32 tmp = a[i] - res[i] + carry;
        carry =  ((int64_t)a[i] - (int64_t)res[i] + carry >= 0) - 1;
        a[i] = tmp;
	} 
}

// Note: N is a large modulos
// Calculates res = (a + b) mod N.
// a and b represent operands, N is the modulus. They are large integers stored in uint32_t arrays of size elements
void mod_add(uint32_t *a, uint32_t *b, uint32_t *N, uint32_t *res, uint32_t size)
{
	uint64_t carry = 0;
	uint32_t tmp_res[32];
    for (uint32_t i = 0;i < size;i++) {
        tmp_res[i] = a[i] + b[i] + carry;
        carry = (((uint64_t)a[i] + b[i] + carry) >> 32);
    }
    //tmp_res[size] = carry;

    if (mp_compare(tmp_res,N,size,carry == 1)) {
        mp_sub(tmp_res,N,res,size);
    }
    else {
    	mp_duplicate(tmp_res,res,size);
    }

    //res[size] = 0; // TODO: when carry is 1

}


// Calculates res = (a - b) mod N.
// a and b represent operands, N is the modulus. They are large integers stored in uint32_t arrays of size elements
void mod_sub(uint32_t *a, uint32_t *b, uint32_t *N, uint32_t *res, uint32_t size)
{
    // ensure that a >= b
    uint8_t flag = mp_compare(a,b,size,false);
    uint32_t tmp_res[32];
    if(flag){
    	mp_sub(a,b,res,size);  // a-b
    } else {
    	mp_sub(b,a,tmp_res,size); // N -（a -b）
        mp_sub(N,tmp_res,res,size);
    }
}
