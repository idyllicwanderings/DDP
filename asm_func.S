 //******** ADD_3: add r0, r1, r2, r3, store #sum in r0 ************************/ 
 .text

.global add_3
.func add_3, add_3
.type add_3, %function

add_3: 
add r0, r0, r1
add r0, r0, r2
bx lr  //**** jumping back to main**********/ 
.endfunc





//********* ADD_10 : add ten?(r1) elements together, starting addr at [r0], 
				//return #sum in r0 ************************/ 
.text

.global add_10
.func add_10, add_10
.type add_10, %function


add_10:
cmp r1, #0
beq end_add
mov r2, #0
add_loop:
	ldr r3, [r0], #4 	
	add r2, r2, r3
	subs r1, r1, #1
	bne  add_loop
mov r0, r2
end_add:
bx lr
.endfunc




//********* ARR_COPY : copy the str from addr at [r0] to [r0], r2 is the size ************************/ 
.text

.global arr_copy
.func arr_copy, arr_copy
.type arr_copy, %function

// arr_copy:
// cmp r2, #0
// beq end_copy
// copy_loop:
// 	ldr r3, [r0], #4
// 	str r3, [r1], #4
// 	subs r2, r2, #1
// 	bne  copy_loop
// end_copy:
// bx lr
// .endfunc


arr_copy:
ldmia r0!, {r2-r10}
stmia r1!, {r2-r10}

ldmia r0!, {r2-r10}
stmia r1!, {r2-r10}

ldmia r0!, {r2-r10}
stmia r1!, {r2-r10}

ldmia r0, {r2-r6}
stmia r1, {r2-r6}	//32 words
end_copy:
bx lr
.endfunc






//********* MULTIPLY : multiply two 64 bit integers in @m, @n pointer, store the results in ? ************************/ 

.text

.global multiply
.func multiply, multiply
.type multiply, %function


// temporary regs: r6,r7
// multiplication with 2 64-bit integers?
// what does r0, r1 stand for?
multiply:

	push {r4-r9}
	// If more registers are used in the function,
	// make sure to do push them on the stack to preserve them
	ldr r4, [sp, #24]		@m pointer is stored in R4
	ldr r5, [sp, #28]		@n pointer is stored in R5
	add r1, r1, r0, lsl #2 // r1 = r1 + r0 << 2 
	ldr r6, [r4]           // a[i]
	ldr r7, [r5]  		   // b[i]
	umull r8, r9, r6, r7   // a[i] * b[i]
	ldr r6, [r2]		   //  
	ldr r7, [r3]     	   //
	umull r4, r5, r6, r7  
	adds r8, r8, r4   	   // set carry flags with ADDS
	adc r9, r9, r5    	   // r9 = r9 + r5 + carry
	stmia r1, {r8, r9}	   // save post-increment store in r1 from r8, r9
	pop {r4-r9}
	bx lr

.endfunc




// ************************* MY CODE GOES HERE *****************************************//




// ************************* initialization *****************************************//
// *************************input(r0:res*,r1:size), output() *****************************************//
.text

.global init
.func init, init
.type init, %function


init:
	mov r2,#0
	mov r3,#0
	mov r4,#0
	mov r5,#0
	mov r6,#0
	mov r7,#0
	mov r8,#0
	mov r9,#0
	mov r10,#0
	stmia r0!, {r2-r10}
	stmia r0!, {r2-r10}
	stmia r0!, {r2-r10}
	stmia r0, {r2-r8}	// 34 words
end_init:
bx lr

.endfunc





// ************************* multiplication *****************************************//
// *************************input(r0:a*,b*,t*,size), output() *****************************************//
.text

.global mult
.func mult,mult
.type mult, %function



mult:
	// default input: r0: a0, r1: b0, r2:t, r3:size
	
	// r4: i, r5: carry, r10: t[size]_addr
	// r0,r1 stored in stack
	

	push {r11,r12,r14}
				
	mov r4,#0					// load i
	add r10,r2,r3,lsl #2		// load t[size]_addr

	ldmia r10, {r6-r7}			// load t[size],t[size+1]
	push {r6-r7}
	
	loop_mult:
		
	
		// LOOP MULT
		// temp: r6: a[j]_addr, r7:b[i]_value, r8:t[i+j]_addr ,r9:a[size-i]_addr
		mov r5,#0						// carry = 0;

		mov r6, r0              		// load a[j]_addr
		add r8, r2,r4,lsl #2			// load t[i+j]_addr
		

		add r9,r1,r4,lsl #2				// load b[i]_addr
		ldr r7,[r9]						// load b[i]_value!

		sub r9,r3,r4					// size - i
		add r9,r0,r9,lsl #2				// a[size-i]_addr
		

		loop_j:

			// sum = t[i + j] +  (u64)a[j] * b[i] + carry; 
			ldr r12, [r6],#4			// load a[j]

			// CAUTION: p{cond}{S} RdLo, RdHi, Rm, Rs!!!
			// r11: sum
			mov r14,#0					// clear the sum!
			umlal r5,r14,r12,r7			// a[j] * b[i] + carry(low_addr)
			ldr r12,[r8]				// load t[i+j]

			adds r11,r5,r12				// + y[i+j]
			adc r5,r14,#0				// CARRY bits
			
			// CAUTION: cmp and adds both set the carry flags!
			cmp r6,r9					
			str r11, [r8],#4 			//save the t[i+j] back

			blt loop_j
		
		pop {r6-r7}
		//ldmia r10, {r6-r7}				// load t[size], t[size+1]
		
		adds r6,r6,r5					//	sum = t[size] + carry;


		mov r5,#0
		adc r5,r5,#0					// carry
		add r7,r7,r5
		

		
		add r4, r4, #1				//do_while loop judgement
		cmp r4, r3
		
		push {r6-r7}
		
		blt  loop_mult

stmia r10, {r6,r7}
pop {r6,r7,r11,r12,r14}
bx lr

.endfunc








// ************************* reduction *****************************************//
// ************************* input(r0:a*,b*,n*,n_prime*,t*,size), output() *****************************************//
.text

.global reduct
.func reduct,reduct
.type reduct, %function


reduct:

	// r0: a0, r1: b0, r2:n0, r3 = n_prime[0], r4:t, r5: size
	// r6:i, r8:carry, r9:m 
	
	pop {r4-r5}   								//load t into r4, size into r5
	push {r11,r12,r14}

	ldr r3, [r3]     							// r3 = n_prime[0]
	mov r6, #0           						// r6:i
	
	push {r3}

loop_reduct:

	ldr r12, [r4]     // load t[0]
	ldr r11,[r2] 	 // load n[0]

	pop {r3}

	umull r9,r8,r12,r3    						// random, r9:m = np[0] * t[0]
	
	push {r3}

	// this line moves up to reduce data dependency//
	add r7,r4,r5,lsl #2 						// load t[size]_addr
	
	
	mov r8,#0
	umlal r12,r8,r9,r11  						// r8:carry, random = t[0] + m * n[0];

	// LOOP J 1:  
	// TODO: t[0] can be saved in REGS! 
	// temp: r10: n[j]_addr, r11: t[j]_addr, r7:t[size]_addr
	// r3: CAN BE RE-USED now!

	add r10, r2,#4		// load n0 +4 :n[j], starting from n[1]
	add r11, r4,#4 		// load t0 +4 :t[j] starting from t[1]
	


	loop_j1:
		ldr r14,[r10],#4		// load n[j]
		ldr r12,[r11],#4		// load t[j], prepare for next t[j+1]
		
		mov r3,#0				// clear r3 for umlal r8,r3,r14,r9
		umlal r8,r3,r14,r9		// m * n[j] + carry

		
		adds r14,r8,r12			// + t[j]
		adc r8,r3,#0			// (carry bits)
		
		cmp r11, r7				// jump if t[j]_addr < t[size]
		str r14,[r11,#-8]		// store t[j-1]
		blt loop_j1				// jump if j < size


	end_j1:

		//temp: save r[7], which should now be t[size]_addr
		ldr r10, [r7],#4 		// load t[size]
		ldr r12, [r7],#-8 		// load t[size+1]

		adds r10,r10,r8			// r10(sum) = t[size] + carry;
		

		mov r14,#0				// r14 = 0;
		adc r8,r14,#0			// carry = (carry bits)
		
		add r12,r12,r8			// r12 = t[size + 1] + carry;
	
		
		stmia r7,{r10,r12,r14}	// store t[size - 1], t[size] ,t[size + 1]
		


	push {r2}						// r3 already on the stack!

	add r10,r6,#1					// j= i + 1
	
	//Caution: skip loop if j = i+1 >= size!
	cmp r10,r5
	add r11,r1,r10,lsl #2			// r11: load b[j]_addr
	bge next_reduc
		

	sub r10,r5,#1					// size - 1
	add r7,r4,r10,lsl #2			// r7: t[size -1]_addr
	
	ldmia r7,{r3,r7,r9}				// load t[i-1],t[i],t[i+1]


	add r2,r1,r10,lsl #2			// r2: load b[size-1]_addr    MODIFIED!
	add r10,r0,r10,lsl #2         	// r10: load a[size+i-j]_addr, starting from size-1
	
	//LOOP J 2:  
	// m(r9)'s regs can be released
	// keep r2,r3 on the sp
	// temp: r2: b[size-1]_addr,r10: a[size-j+i]_addr,
	//		 r11: b[j]_addr, r3: t[s-1],r7: t[s], r9:t[s+1]


	loop_j2:
		ldr r12,[r11],#4			//l oad b[j], j+1
		ldr r14,[r10],#-4			// load a[size+i-j]_addr, index -1

		mov r8,#0
		umlal r3,r8,r12,r14			// b[j] * a[size - j + i] + t[size - 1]

		adds r7,r7,r8				//t[size] = sum; sum = t[size] + carry;
		mov r8,#0
		adc r9,r9,#0				// t[size + 1] += carry;
		
		cmp r11,r2  				// continue if j <= size - 1 
		ble	loop_j2

	end_j2:
		sub r10,r5,#1				// size - 1
		add r10,r4,r10,lsl #2		// t[size-1]_addr

		stmia r10, {r3,r7,r9}		//store the t[s-1], t[s], t[s+1]

	next_reduc:
	
	
	add r6,r6,#1   					// i ++;
	
	cmp r6,r5
	pop {r2}					//restore the r2 only, r3 will be retrived by next loop of loop_reduct
	blt loop_reduct					// do while {i < size}

pop {r3,r11,r12,r14}

bx lr

.endfunc









// ************************* SUB_CONDITION *****************************************//
// *************************input(r0:t*,n*,size), output() *****************************************//
.text

.global condsub
.func condsub,condsub
.type condsub, %function



    
condsub:
	// r0: t, r1:n , r2: size
	// r5:load t[size]
	
	//temp: r3: n[i]_addr, r4: t[i]_addr
	add r4,r0,r2, lsl #2		// load t[size]_addr
	ldr r5,[r4],#-4				// r5:load t[size], prep for t[size-1]
	sub r3,r2,#1

	cmp r5,#0
	add r3,r1,r3,lsl #2			//LOAD n[i], starting from n[size-1]
	bgt start_sub
	
	
	loop_cmp:
		ldr r6,[r4],#-4			// load t[i]
		ldr r7,[r3],#-4			//LOAD n[i]
		
		//CAUTION: this is unsigned compare branch, us BLO and BHI instead.
		cmp r6,r7				// jump to end if t < n
		blo end_consub
		
		cmp r6,r7
		bhi start_sub			// jump to sub if t > n
		
		cmp r4,r0
		blt start_sub			// jump to sub if t[all] = n[all]
	
		cmp r6,r7				// jump to loop_cmp start if t = n
		beq loop_cmp
		
	
	b end_consub				// jump to end
	
	

	start_sub:
		// r14: reg for zero, r12: reg for carry
		push {r11,r12,r14}
		mov r14,#0				// set carry flag = 0
		
		ldmia r0,{r2-r5}		// 1
		ldmia r1!,{r6-r9}
		
		subs r2,r2,r6
		sbcs r3,r3,r7
		sbcs r4,r4,r8
		sbcs r5,r5,r9
		
		stmia r0!,{r2-r5}
		
		
		ldmia r0,{r2-r5}		// 2
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbcs r14,r5,r9
		
		stmia r0!,{r10-r12,r14}
	
		ldmia r0,{r2-r5}		// 3
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbcs r14,r5,r9
		
		stmia r0!,{r10-r12,r14}
		
		ldmia r0,{r2-r5}		// 4
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbcs r14,r5,r9
		
		stmia r0!,{r10-r12,r14}
		
		
		ldmia r0,{r2-r5}		// 5
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbcs r14,r5,r9
		
		stmia r0!,{r10-r12,r14}
		
		
		ldmia r0,{r2-r5}		// 6
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbcs r14,r5,r9
		
		stmia r0!,{r10-r12,r14}
		
		ldmia r0,{r2-r5}		// 7
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbcs r14,r5,r9
		
		stmia r0!,{r10-r12,r14}	

		ldmia r0,{r2-r5}		// 8
		ldmia r1!,{r6-r9}
		
		sbcs r10,r2,r6
		sbcs r11,r3,r7
		sbcs r12,r4,r8
		sbc r14,r5,r9
		
		stmia r0!,{r10-r12,r14}
		
		
		pop {r11,r12,r14}
		

end_consub:
bx lr


.endfunc





// ************************* APPENDIX  *****************************************//
@USEFUL FUNCTIONS

@ add Rx, Ry, Rz	//Rx = Ry + Rz  second operand can be constant
@ sub Rx, Ry, Rz	//Rx = Ry - Rz second operand can be constant
@ addc Rx, Ry, Rz	//Rx = Ry + Rz + CARRY   one operand can be constant
@ cmp Rx, Ry		//compares Rx and Ry and if they are equal sets Z flag, otherwise resets Z flag (works by subtracting two values and checks if result is zero)
@ b{cond} <label>		//Jumps to given label in the code if given condition is satisfied
@ umull Rn, Rm, Rx, Ry 	//{Rm, Rn} = Rx * Ry Multiplies unsigned 32bit values in Rx and Ry. Stores the higher 32 bits in Rm, and lower in Rn
@ ldr Rx, [Ry]		//Loads from memory pointed by Ry to register Rx, see addressing modes for post increment, pre decrement
@ str Rx, [Ry]		//Stores to memory pointed by Ry value in register Rx, see addressing modes for post increment, pre decrement
@ pop {}			//Pops values from stack to specified registers in order they are specified
@ push {}			//Push registers to stack in orded they are specified
@ ldmia rx, {set of registers} 
//Loads to specified set of registers memory values,
// starting from rx. Increasing addresses
@ stmia rx, {set of registers} 
//Stores specified set of registers in memory, 
// starting from address pointed by rx. Increasing addresses
