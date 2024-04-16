/*
 * montgomery.h
 *
 */

#ifndef MONTOGOMERY_H_
#define MONTOGOMERY_H_

#include <stdint.h>

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// You cannot change this definition!
void montMul(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size);

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// You cannot change this definition!
void montMulOpt(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size);



#endif /* MONTOGOMERY_H_ */
