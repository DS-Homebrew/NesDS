@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper189init

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

	irq_enable	= mapperData+20
	irq_counter	= mapperData+21
	irq_latch	= mapperData+22
	patch		= mapperData+24
	lwd		= mapperData+25

	datar0		= mapperData+26


@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ This mapper is a modified MMC3.
@ Everything operates just as it does on the MMC3, only the normal PRG regs
@ (R:6,R:7) are ignored, and a new PRG Reg is used instead.
@ Used in:
@ Thunder Warrior
mapper189init:
@---------------------------------------------------------------------------------
	.word write0, write1, write2, write3
	stmfd sp!, {lr}
	mov r0, #0
	str_ r0, reg0
	str_ r0, reg4

	mov r0, #-1
	bl map89ABCDEF_

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
	strb_ r0, patch

	adr r0, hsync
	str_ r0,scanlineHook

	adr r0, writel
	str_ r0, m6502WriteTbl+12
	str_ r0, m6502WriteTbl+8

	ldr_ r0, prgcrc
	ldr r1, =0x2A9E
	cmp r0, r1
	streqb_ r1, patch

	ldmfd sp!, {pc}

@-------------------------------------------------------------------
writel:
	cmp addy, #0x4100
	bcc IO_W

	strb_ r0, datar0

	stmfd sp!, {lr}
	mov r1, addy, lsr#8
	cmp r1, #0x41
	bne 0f
	and r0, r0, #0x30
	mov r0, r0, lsr#4
	bl map89ABCDEF_
	b chpatch

0:
	cmp r1, #0x61
	bne chpatch
	and r0, r0, #0x3
	bl map89ABCDEF_

chpatch:

	ldrb_ r0, patch
	ands r0, r0, r0
	beq chend

	cmp addy, #0x4800
	bcc 0f
	cmp addy, #0x5000
	bcs 0f
	ldrb_ r1, datar0
	and r0, r1, #1
	tst r1, #0x10
	orrne r0, r0, #0x2
	bl map89ABCDEF_

	ldrb_ r0, datar0
	tst r0, #0x20
	bl mirror2V_
	b chend
0:
	cmp addy, #0x5000
	bcc 0f
	cmp addy, #0x5800
	bcs 0f
	ldrb_ r0, datar0
	strb_ r0, lwd
	b chend
0:
	cmp addy, #0x5800
	bcc chend
	cmp addy, #0x6000
	bcs chend

	adr r2, a5000xordat
	ldrb_ r1, lwd
	ldrb r2, [r2, r1]
	ldrb_ r1, datar0
	eor r2, r1, r2
	and r1, addy, #0x3
	add r1, r1, #0x1800
	ldr r0, =NES_XRAM
	strb r2, [r0, r1]
chend:
	ldmfd sp!, {pc}

@-------------------------------------------------------------------
setbank_ppu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}

	ldrb_ r0, patch
	ands r0, r0, r0
	beq 0f

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

0:
	ldrb_ r0, reg0
	tst r0, #0x80
	beq 0f

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

@-------------------------------------------------------------------
hsync:
@-------------------------------------------------------------------
	ldr_ r0, scanline
	cmp r0, #240
	bxcs lr

	ldrb_ r1, ppuCtrl1
	tst r1, #0x18
	bxeq lr

	ldrb_ r1, irq_enable
	ands r1, r1, r1
	bxeq lr

	ldrb_ r1, irq_counter
	subs r1, r1, #1
	strb_ r1, irq_counter
	bxne lr
	ldrb_ r0, irq_latch
	strb_ r0, irq_counter
	mov r0,#1
	b rp2A03SetIRQPin

@------------------------------------
write0:
@------------------------------------
	tst addy, #1
	bne w8001

	strb_ r0, reg0
	b setbank_ppu

w8001:
	strb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #0x7
	adrl_ r2, chr01
	cmp r1, #0x02
	andcc r0, r0, #0xFE
	cmp r1, #0x06
	strccb r0, [r2, r1]

	b setbank_ppu
@------------------------------------
write1:
@------------------------------------
	tst r0, #1
	b mirror2V_

@------------------------------------
write2:
@------------------------------------
	tst addy, #1
	bne wc001

	strb_ r0, irq_counter
	bx lr

wc001:
	strb_ r0, irq_latch
	bx lr

@------------------------------------
write3:
@------------------------------------
	and r0, addy, #1
	strb_ r0, irq_enable
	bx lr
@------------------------------------
a5000xordat:
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x49, 0x19, 0x09, 0x59, 0x49, 0x19, 0x09
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x51, 0x41, 0x11, 0x01, 0x51, 0x41, 0x11, 0x01
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x49, 0x19, 0x09, 0x59, 0x49, 0x19, 0x09
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x51, 0x41, 0x11, 0x01, 0x51, 0x41, 0x11, 0x01
.byte 0x00, 0x10, 0x40, 0x50, 0x00, 0x10, 0x40, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x08, 0x18, 0x48, 0x58, 0x08, 0x18, 0x48, 0x58, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x00, 0x10, 0x40, 0x50, 0x00, 0x10, 0x40, 0x50, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x08, 0x18, 0x48, 0x58, 0x08, 0x18, 0x48, 0x58, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x58, 0x48, 0x18, 0x08, 0x58, 0x48, 0x18, 0x08
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x50, 0x40, 0x10, 0x00, 0x50, 0x40, 0x10, 0x00
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x58, 0x48, 0x18, 0x08, 0x58, 0x48, 0x18, 0x08
.byte 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x59, 0x50, 0x40, 0x10, 0x00, 0x50, 0x40, 0x10, 0x00
.byte 0x01, 0x11, 0x41, 0x51, 0x01, 0x11, 0x41, 0x51, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x09, 0x19, 0x49, 0x59, 0x09, 0x19, 0x49, 0x59, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x01, 0x11, 0x41, 0x51, 0x01, 0x11, 0x41, 0x51, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.byte 0x09, 0x19, 0x49, 0x59, 0x09, 0x19, 0x49, 0x59, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
