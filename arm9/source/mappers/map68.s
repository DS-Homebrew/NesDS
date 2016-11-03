@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	.global mapper68init

	reg0 = mapperdata
	reg1 = mapperdata + 1
	reg2 = mapperdata + 2
	reg3 = mapperdata + 3
@---------------------------------------------------------------------------------
mapper68init:	@Sunsoft, After Burner...
@---------------------------------------------------------------------------------
	.word write0,write1,write2,write3
	mov r0, #-1
	str r0, bank_cache

	mov pc,lr
@---------------------------------------------------------------------------------
write0:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	bne chr23_
	b chr01_
@---------------------------------------------------------------------------------
write1:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	bne chr67_
	b chr45_
@---------------------------------------------------------------------------------
write2:
@---------------------------------------------------------------------------------
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
	b setNTmanualy
@---------------------------------------------------------------------------------
write3:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	bne map89AB_

	and r2, r0, #3
	strb_ r2, reg1
	tst r0,#0x10
	bne setNTmanualy
	b mirrorKonami_
@----------------------
setNTmanualy:
	stmfd sp!, {r3-r9, lr}
	ldr_ r3, vrombase
	add r3, r3, #(0x80<<10)			@cal the base
	ldrb_ r4, reg2
	ldrb_ r5, reg3

	@add r4, r3, r4, lsl#10			@first bank
	@add r5, r3, r5, lsl#10			@second bank

	ldr r2, =NDS_BG + 0x2000		@point to a free Map area.
	ldrb r0, bank_cache
	cmp r0, r4
	strneb r4, bank_cache
	addne r4, r3, r4, lsl#10			@first bank
	blne fresh_bank

	ldr r2, =NDS_BG + 0x2800
	ldrb r0, bank_cache + 1
	cmp r0, r5
	strneb r5, bank_cache
	addne r4, r3, r5, lsl#10			@second bank
	blne fresh_bank

	mov r0, #0x1C00				@change the map base
	ldrb_ r1, reg1
	cmp r1, #0
	addeq r0, r0, #0x4000
	cmp r1, #1
	addeq r0, r0, #0x8000
	cmp r1, #3
	addeq r0, r0, #0x0100
	str_ r0, bg0cnt

	ldmfd sp!, {r3-r9, pc}

@------------------------
fresh_bank:
	add r6, r4, #0x3C0			@the tile attr base.
	adr r7, ntdata
	mov r9, #8*8

nt_loop:
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
	tst r9, #7				@one row will be 8 bytes
	addne r7, r7, #2
	addeq r7, r7, #18
	b nt_loop
	
0:
	mov r6, #0
	adr r7, ntdata

tilenum_loop:
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
	bcc tilenum_loop

	mov pc, lr

@---------------------------------------------------------------------------------
bank_cache:
	.skip 4
ntdata:
	.skip 8*8*2*2