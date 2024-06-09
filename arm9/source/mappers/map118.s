@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper118init

	reg0 = mapperData
	reg1 = mapperData+1
	reg2 = mapperData+2
	reg3 = mapperData+3
	reg4 = mapperData+4
	reg5 = mapperData+5
	reg6 = mapperData+6
	reg7 = mapperData+7

	chr01 = mapperData+8
	chr23 = mapperData+9
	chr4  = mapperData+10
	chr5  = mapperData+11
	chr6  = mapperData+12
	chr7  = mapperData+13

	prg0  = mapperData+14
	prg1  = mapperData+15

	irq_enable	= mapperData+16
	irq_counter	= mapperData+17
	irq_latch	= mapperData+18

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ MMC3 on TKSROM & TLSROM boards
@ Used in:
@ Armadillo
@ Pro Sport Hockey
@ Also see mapper 95, 158 & 207
mapper118init:
@---------------------------------------------------------------------------------
	.word write0, empty_W, write2, write3
	stmfd sp!, {lr}
	mov r0, #0
	str_ r0, reg0
	str_ r0, reg4

	mov r0, #0x0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1

	bl setbank_cpu

	mov r0, #0
	strb_ r0, chr01
	mov r0, #2
	strb_ r0, chr23
	mov r0, #4
	strb_ r0, chr4
	mov r0, #5
	strb_ r0, chr5
	mov r0, #6
	strb_ r0, chr6
	mov r0, #7
	strb_ r0, chr7

	bl setbank_ppu

	mov r0, #0
	str_ r0, irq_enable

	ldr r0,=hsync
	str_ r0,scanlineHook

	ldmfd sp!, {pc}
@-------------------------------------------------------------------
setbank_cpu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, reg0
	tst r0, #0x40
	beq sbc1

	mov r0, #-2
	bl map89_
	ldrb_ r0, prg0
	bl mapCD_
	ldmfd sp!, {lr}
	mov r0, #-1
	b mapEF_

sbc1:
	ldrb_ r0, prg0
	bl map89_
	ldmfd sp!, {lr}
	mov r0, #-1
	b mapCDEF_

@-------------------------------------------------------------------
setbank_ppu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}

	ldrb_ r0, reg0
	tst r0, #0x80
	beq 0f

	mov r1, #0
	ldrb_ r0, chr4
	bl chr1k
	mov r1, #1
	ldrb_ r0, chr5
	bl chr1k
	mov r1, #2
	ldrb_ r0, chr6
	bl chr1k
	mov r1, #3
	ldrb_ r0, chr7
	bl chr1k
	mov r1, #4
	ldrb_ r0, chr01
	bl chr1k
	mov r1, #5
	ldrb_ r0, chr01
	add r0, r0, #1
	bl chr1k
	mov r1, #6
	ldrb_ r0, chr23
	bl chr1k
	mov r1, #7
	ldrb_ r0, chr23
	add r0, r0, #1
	bl chr1k
	ldmfd sp!, {pc}

0:
	mov r1, #0
	ldrb_ r0, chr01
	bl chr1k
	mov r1, #1
	ldrb_ r0, chr01
	add r0, r0, #1
	bl chr1k
	mov r1, #2
	ldrb_ r0, chr23
	bl chr1k
	mov r1, #3
	ldrb_ r0, chr23
	add r0, r0, #1
	bl chr1k
	mov r1, #4
	ldrb_ r0, chr4
	bl chr1k
	mov r1, #5
	ldrb_ r0, chr5
	bl chr1k
	mov r1, #6
	ldrb_ r0, chr6
	bl chr1k
	mov r1, #7
	ldrb_ r0, chr7
	bl chr1k
	ldmfd sp!, {pc}

@------------------------------------
write0:
@------------------------------------
	stmfd sp!, {lr}
	tst addy, #1
	bne w8001

	strb_ r0, reg0
	bl setbank_cpu
	bl setbank_ppu
	ldmfd sp!, {pc}

w8001:
	strb_ r0, reg1
	ldrb_ r1, reg0
	tst r1, #0x80
	and r1, r1, #7
	beq 0f
	cmp r1, #2
	bne 1f
	adr lr, 1f
	tst r0, #0x80
	b mirror1H_	
0:
	cmp r1, #0
	bne 1f
	tst r0,#0x8
	bl mirror1H_
1:
	ldrb_ r1, reg0
	ldrb_ r0, reg1
	and r1, r1, #7
	cmp r1, #2
	andcc r0, r0, #0xfe
	adrl_ r2, chr01
	strb r0, [r2, r1]
	ldmfd sp!, {lr}
	cmp r1, #6
	bcc setbank_ppu
	b setbank_cpu

@------------------------------------
write2:
@------------------------------------
	tst addy, #1
	bne wc001

	strb_ r0, reg4
	strb_ r0, irq_counter
	bx lr

wc001:
	strb_ r0, reg5
	strb_ r0, irq_latch
	bx lr
	
@------------------------------------
write3:
@------------------------------------
	tst addy, #1
	bne we001

	strb_ r0, reg6
	mov r0, #0
	strb_ r0, irq_enable
	bx lr

we001:
	strb_ r0, reg7
	mov r0, #1
	strb_ r0, irq_enable
	bx lr

@-------------------------------------------------------------------
hsync:
@-------------------------------------------------------------------
	ldr_ r0, scanline
	cmp r0, #240
	bcs hq
	ldrb_ r1, ppuCtrl1
	tst r1, #0x18
	beq hq

	ldrb_ r0, irq_enable
	ands r0, r0, r0
	beq hq

	ldrb_ r2, irq_counter
	subs r2, r2, #1
	strneb_ r2, irq_counter
	bne hq

	ldrb_ r0, irq_latch
	strb_ r0, irq_counter
	b CheckI
hq:
	fetch 0
