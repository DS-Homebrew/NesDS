;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper68init

	.struct mapperData
reg0:		.byte 0
reg1:		.byte 0
reg2:		.byte 0
reg3:		.byte 0
bankCache:	.space 4
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Sunsoft-4
;@ Used in:
;@ After Burner...
mapper68init:
;@----------------------------------------------------------------------------
	.word write0,write1,write2,write3
	mov r0, #-1
	str_ r0, bankCache

	bx lr
;@----------------------------------------------------------------------------
write0:
;@----------------------------------------------------------------------------
	tst addy,#0x1000
	bne chr23_
	b chr01_
;@----------------------------------------------------------------------------
write1:
;@----------------------------------------------------------------------------
	tst addy,#0x1000
	bne chr67_
	b chr45_
;@----------------------------------------------------------------------------
write2:
;@----------------------------------------------------------------------------
	tst addy, #0x1000
	streqb_ r0, reg2
	strneb_ r0, reg3
	/*
	stmfd sp!, {lr}
	add r0, r0, #0x80
	moveq r1, #8
	movne r1, #9
	bl chr1k
	ldmfd sp!, {lr}
	*/
	b setNTManualy
;@----------------------------------------------------------------------------
write3:
;@----------------------------------------------------------------------------
	tst addy,#0x1000
	bne map89AB_

	and r2, r0, #3
	strb_ r2, reg1
	tst r0,#0x10
	bne setNTManualy
	b mirrorKonami_
;@----------------------
setNTManualy:
	stmfd sp!, {r3-r9, lr}
	ldr_ r3, vmemBase
	add r3, r3, #(0x80<<10)		;@ Cal the base
	ldrb_ r4, reg2
	ldrb_ r5, reg3

	@add r4, r3, r4, lsl#10		;@ First bank
	@add r5, r3, r5, lsl#10		;@ Second bank

	ldr r2, =NDS_BG + 0x2000	;@ Point to a free Map area.
	ldrb_ r0, bankCache
	cmp r0, r4
	strneb_ r4, bankCache
	addne r4, r3, r4, lsl#10	;@ First bank
	blne freshBank

	ldr r2, =NDS_BG + 0x2800
	ldrb_ r0, bankCache + 1
	cmp r0, r5
	strneb_ r5, bankCache +1
	addne r4, r3, r5, lsl#10	;@ Second bank
	blne freshBank

	mov r0, #0x1C00				;@ Change the map base
	ldrb_ r1, reg1
	cmp r1, #0
	addeq r0, r0, #0x4000
	cmp r1, #1
	addeq r0, r0, #0x8000
	cmp r1, #3
	addeq r0, r0, #0x0100
	str_ r0, bg0Cnt

	ldmfd sp!, {r3-r9, pc}

;@------------------------
freshBank:
	add r6, r4, #0x3C0			;@ The tile attr base.
	adr r7, ntData
	mov r9, #8*8

ntLoop:
	ldrb r8, [r6], #1
	and r0, r8, #3
	strb r0, [r7]
	mov r8, r8, lsr#2
	and r0, r8, #3
	strb r0, [r7, #1]
	mov r8, r8, lsr#2
	and r0, r8, #3
	strb r0, [r7, #16]
	mov r8, r8, lsr#2
	strb r8, [r7, #17]

	subs r9, r9, #1
	beq 0f
	tst r9, #7					;@ One row will be 8 bytes
	addne r7, r7, #2
	addeq r7, r7, #18
	b ntLoop

0:
	mov r6, #0
	adr r7, ntData

tilenumLoop:
	mov r1, r6, lsr#6
	and r0, r6, #0x1e
	mov r0, r0, lsr#1
	add r0, r0, r1, lsl#4

	ldrb r1, [r7, r0]
	and r1, r1, #3
	ldrb r0, [r4], #1
	orr r0, r0, r1, lsl#12
	strh r0, [r2], #2
	add r6, r6, #1
	cmp r6, #32*30
	bcc tilenumLoop

	bx lr

;@----------------------------------------------------------------------------
ntData:
	.space 8*8*2*2
