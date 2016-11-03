@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper246init

@---------------------------------------------------------------------------------
mapper246init:
@---------------------------------------------------------------------------------
	.word void, void, void, void
	ldr r0, =writel
	str_ r0, writemem_tbl+12

	mov pc, lr
@---------------------------------------------------------------------------------
writel:
	ldr r1, =0x6008
	cmp addy, r1
	bcs sram_W
	and r1, addy, #0x7
	cmp r1, #0
	beq map89_
	cmp r1, #1
	beq mapAB_
	cmp r1, #2
	beq mapCD_
	cmp r1, #3
	beq mapEF_
	cmp r1, #4
	beq chr01_
	cmp r1, #5
	beq chr23_
	cmp r1, #6
	beq chr45_
	cmp r1, #7
	beq chr67_
	@reach here means something error
	mov pc, lr