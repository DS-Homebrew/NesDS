@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper198init

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

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mapper198init:
@---------------------------------------------------------------------------------
	.word write0, writeABCDEF, writeABCDEF, writeABCDEF
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

	adr r0, readl
	str_ r0, m6502ReadTbl+8
	adr r0, writel
	str_ r0, m6502WriteTbl+8
/*
	adr r0, readh
	str_ r0, m6502ReadTbl+12
	adr r0, writeh
	str_ r0, m6502WriteTbl+12
*/
	ldmfd sp!, {pc}

@-------------------------------------------------------------------
writel:
@-------------------------------------------------------------------
	ldr r2, =0x4019
	cmp addy, r2
	bcc IO_W
	bic r1, addy, #0xE000
	ldr r2, =NES_XRAM
	strb r0, [r2, r1]
	bx lr
@-------------------------------------------------------------------
readl:
@-------------------------------------------------------------------
	ldr r2, =0x4019
	cmp addy, r2
	bcc IO_R
	bic r1, addy, #0xE000
	ldr r2, =NES_XRAM
	ldrb r0, [r2, r1]
	bx lr

@-------------------------------------------------------------------
writeh:
	ldr r1,=NES_SRAM
	bic r2, addy, #0xE000
	strb r0,[r1,r2]
	bx lr
@-------------------------------------------------------------------
readh:
	ldr r1,=NES_SRAM	
	bic r2, addy, #0xE000
	ldrb r0,[r1,r2]
	bx lr
@-------------------------------------------------------------------
setbank_cpu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}
	ldrb_ r0, reg0
	tst r0, #0x40
	beq sbc1

	mov r0, #-2
	bl map89_
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, prg0
	bl mapCD_
	mov r0, #-1
	bl mapEF_
	b cend

sbc1:
	ldrb_ r0, prg0
	bl map89_
	ldrb_ r0, prg1
	bl mapAB_
	mov r0, #-1
	bl mapCDEF_

cend:
	ldmfd sp!, {pc}

@-------------------------------------------------------------------
setbank_ppu:
@-------------------------------------------------------------------
	ldr_ r1, vromMask
	tst r1, #0x80000000
	bxne lr

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
	tst addy, #1
	bne w8001

	stmfd sp!, {lr}
	strb_ r0, reg0
	bl setbank_cpu
	bl setbank_ppu
	ldmfd sp!, {pc}

w8001:
	strb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #7
	cmp r1, #6
	bcs 6f
0:
	cmp r1, #2
	andcc r0, r0, #0xfe
	adrl_ r2, chr01
	strb r0, [r2, r1]
	b setbank_ppu
6:
	bne 7f
	cmp r0, #0x50
	andcs r0, r0, #0x4f
	strb_ r0, prg0
	b setbank_cpu
7:
	strb_ r0, prg1
	b setbank_cpu

@------------------------------------
writeABCDEF:
	mov r1, addy, lsr#12
	tst addy, #1
	biceq r1, r1, #1
	orrne r1, r1, #1
	subs r1, r1, #0xa
	adrl_ r2, reg2
	strb r0, [r2, r1]
	bxne lr
	tst r0, #1
	b mirror2V_
