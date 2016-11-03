@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper91init
@---------------------------------------------------------------------------------
mapper91init:
@---------------------------------------------------------------------------------
	.word void, void, void, void

	stmfd sp!, {lr}
	mov r0, #-1
	bl map89AB_
	mov r0, #-1
	bl mapCDEF_

	mov r0, #0
	bl chr0_
	mov r0, #0
	bl chr1_
	mov r0, #0
	bl chr2_
	mov r0, #0
	bl chr3_
	mov r0, #0
	bl chr4_
	mov r0, #0
	bl chr5_
	mov r0, #0
	bl chr6_
	mov r0, #0
	bl chr7_

	adr r0, hsync
	str_ r0,scanlinehook
	
	adr r1,writel
	str_ r1,writemem_tbl+12
	
	ldmfd sp!, {pc}
@---------------------------------------------------------------------------------
writel:
@---------------------------------------------------------------------------------
	cmp addy, #0x7000
	bcs addhi
	and r1, addy, #3
	add r1, r1, r1
	b chr2k

addhi:
	cmp addy, #0x8000
	movcs pc, lr
	and r2, addy, #3
	cmp r2, #0
	beq map89_
	cmp r2, #1
	beq mapAB_
	mov pc, lr


@---------------------------------------------------------------------------------
hsync:
	ldr_ r0, scanline
	cmp r0, #240
	bcs hk

	ands r0, r0, #7
	beq CheckI
hk:
	fetch 0