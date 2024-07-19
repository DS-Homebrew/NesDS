;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper40init

	.struct mapperData
countdown:	.word 0
irqEn:		.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
mapper40init:		;@ SMB2j
;@----------------------------------------------------------------------------
	.word write0,write1,void,mapCD_

	stmfd sp!, {lr}
	adr r0,hook
	str_ r0,scanlineHook

	ldr r0,=empty_W			;@ Set ROM at $6000-$7FFF.
	str_ r0,m6502WriteTbl+12

	bl write0

	mov r0,#-1
	bl map89ABCDEF_

	ldmfd sp!, {lr}
	mov r0,#6
	b map67_
;@----------------------------------------------------------------------------
write0:		;@ $8000-$9FFF
;@----------------------------------------------------------------------------
	mov r0,#36
	str_ r0,countdown
	mov r0,#0
	strb_ r0,irqEn
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
write1:		;@ $A000-$BFFF
;@----------------------------------------------------------------------------
	mov r0,#1
	strb_ r0,irqEn
	bx lr
;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb_ r0,irqEn
	cmp r0,#0
	bxeq lr

	ldr_ r0,countdown
	subs r0,r0,#1
	str_ r0,countdown
	bxcs lr

	mov r0,#0
	strb_ r0,irqEn
	mov r0,#1
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
