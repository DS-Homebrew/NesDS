@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper246init

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Used in Taiwanese game
@ 封神榜 (Fēngshénbǎng: Fúmó Sān Tàizǐ).
mapper246init:
@---------------------------------------------------------------------------------
	.word void, void, void, void
	ldr r0, =writel
	str_ r0, m6502WriteTbl+12

	bx lr
@---------------------------------------------------------------------------------
writel:
	ldr r1, =0x6008
	cmp addy, r1
	bcs sram_W
	ands r1, addy, #0x7
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
	bx lr
