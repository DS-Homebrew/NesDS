;@----------------------------------------------------------------------------
	#include "equates.h"

	.global mapper42init

	.struct mapperData
counter:	.word 0
irqEn:		.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ FDS cart conversions
;@ Ai Senshi Nicol
;@ "Mario Baby" (really Bio Miracle Bokutte Upa)
mapper42init:
;@----------------------------------------------------------------------------
	.word chr01234567_,void,void,write3
	stmfd sp!, {lr}

	ldr r1,=mem_R60			;@ Swap in ROM at $6000-$7FFF.
	str_ r1,m6502ReadTbl+12
	ldr r1,=empty_W			;@ ROM.
	str_ r1,m6502WriteTbl+12

	mov r0,#-1
	bl map89ABCDEF_

	adr r0,map42IrqHook
	str_ r0,scanlineHook

	ldmfd sp!, {lr}
	mov r0,#0
	b map67_

;@----------------------------------------------------------------------------
write0:		;@ 8000
;@----------------------------------------------------------------------------
	bx lr
	b chr01234567_
;@----------------------------------------------------------------------------
write3:		;@ E000-E003
;@----------------------------------------------------------------------------
	and r1,addy,#3
	ldr pc,[pc,r1,lsl#2]
nothing:
	bx lr
;@----------------------------------------------------------------------------
commandList:	.word map67_,cmd1,cmd2,nothing
cmd1:
	tst r0,#0x08
	b mirror2V_
cmd2:
	ands r0,r0,#2
	strb_ r0,irqEn
	streq_ r0,counter
	beq rp2A03SetIRQPin
	bx lr
;@----------------------------------------------------------------------------
map42IrqHook:
;@----------------------------------------------------------------------------
	ldrb_ r0,irqEn
	cmp r0,#0
	bxeq lr
	ldr_ r1,counter
	add r0,r1,#113<<17
	str_ r0,counter
	eor r1,r1,r0
	movs r1,r1,lsr#30
	bxeq lr					;@ No change
	mvns r0,r0,asr#30
	moveq r0,#1
	movne r0,#0
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
