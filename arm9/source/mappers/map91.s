;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper91init

	irqEnable	= mapperData
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
mapper91init:
;@----------------------------------------------------------------------------
	.word rom_W, rom_W, rom_W, rom_W

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

	adr r0, hSync
	str_ r0,scanlineHook

	adr r1,writeL
	str_ r1,m6502WriteTbl+12

	ldmfd sp!, {pc}
;@----------------------------------------------------------------------------
writeL:
;@----------------------------------------------------------------------------
	cmp addy, #0x7000
	bcs addHi
	and r1, addy, #3
	add r1, r1, r1
	b chr2k

addHi:
	ands r2, addy, #3
	beq map89_
	cmp r2, #2
	bmi mapAB_
	moveq r0,#0
	movne r0,#1
	strb_ r0,irqEnable
	beq rp2A03SetIRQPin
	bx lr

;@----------------------------------------------------------------------------
hSync:
	ldr_ r0, scanline
	cmp r0, #240
	bxcs lr

	ands r0, r0, #7
	bxne lr
	mov r0,#1
	b rp2A03SetIRQPin
