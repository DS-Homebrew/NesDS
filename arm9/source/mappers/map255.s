;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper225init
	.global mapper255init

	.struct mapperData
tmp:	.word 0
ram0:	.space 4
prgReg:	.byte 0
chrReg:	.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ ET-4310 (60-pin) and K-1010 (72-pin) multicart circuit boards.
;@ Used in:
;@ 52 Games
;@ 58-in-1
;@ 64-in-1
mapper225init:
;@----------------------------------------------------------------------------
	.word w255, w255, w255, w255
	stmfd sp!, {lr}
	mov r0, #0
	bl map89ABCDEF_
	cmp r0, r0
	bl mirror2V_
	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
;@ Same as 225, plus ram.
mapper255init:
;@----------------------------------------------------------------------------
	.word w255, w255, w255, w255
	stmfd sp!, {lr}
	mov r0, #0
	bl map89ABCDEF_
	cmp r0, r0
	bl mirror2V_

	adr r0, m255RamR
	str_ r0, rp2A03MemRead
	adr r0, m255RamW
	str_ r0, rp2A03MemWrite
	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
w255:
;@----------------------------------------------------------------------------
	stmfd sp!, {lr}

	str_ addy, tmp
	mov r0, addy, lsr#6
	and r0, r0, #0x3F
	and r1, addy, #0x3f
	tst addy, #0x4000		;@ 7th bit of both chr & prg
	orrne r0, r0, #0x40
	orrne r1, r1, #0x40
	strb_ r1, chrReg
	strb_ r0, prgReg

	tst addy, #0x2000
	bl mirror2V_

	ldrb_ r0, chrReg
	bl chr01234567_

	ldrb_ r0, prgReg
	ldr_ addy, tmp
	tst addy, #0x1000		;@ Prg mode
	beq w255_32k

	bl map89AB_
	ldmfd sp!, {lr}
	ldrb_ r0, prgReg
	b mapCDEF_

w255_32k:
	ldmfd sp!, {lr}
	mov r0, r0, lsr#1
	b map89ABCDEF_

;@----------------------------------------------------------------------------
m255RamR:
;@----------------------------------------------------------------------------
	tst addy,#0x1800
	beq empty_R
	and r1,addy,#3
	adr_ r2,ram0
	ldrb r0,[r2,r1]
	bx lr
;@----------------------------------------------------------------------------
m255RamW:
;@----------------------------------------------------------------------------
	tst addy,#0x1800
	beq empty_W
	and r1,addy,#3
	adr_ r2,ram0
	strb r0,[r2,r1]
	bx lr
;@----------------------------------------------------------------------------
