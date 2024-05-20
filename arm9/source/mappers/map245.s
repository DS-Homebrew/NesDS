@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper245init

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
	irq_request	= mapperData+19
	we_sram		= mapperData+20
	irq_type	= mapperData+21

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mapper245init:
@---------------------------------------------------------------------------------
	.word write0, write1, void, void
	mov r0, #0
	str_ r0, reg0
	str_ r0, reg4

	mov r0, #0x0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1
	
	mov r0, #0
	str_ r0, irq_enable

	bx lr

@------------------------------------
write0:
@------------------------------------
	tst addy, #1
	bne w8001

	strb_ r0, reg0
	bx lr

w8001:
	stmfd sp!, {lr}
	strb_ r0, reg1
	ldrb_ r1, reg0
	cmp r1, #0
	bne 6f

	ands r2, r0, #2
	movne r2, #(2 << 5)
	strb_ r2, reg3
	orr r0, r2, #0x3E
	bl mapCD_
	ldrb_ r0, reg3
	orr r0, r0, #0x3F
	bl mapEF_
	b 0f
6:
	cmp r1, #6
	bne 7f
	strb_ r0, prg0
	b 0f
7:
	cmp r1, #7
	bne 0f
	strb_ r0, prg1
0:
	ldrb_ r0, prg0
	ldrb_ r1, reg3
	orr r0, r0, r1
	bl map89_
	ldrb_ r0, prg1
	ldrb_ r1, reg3
	orr r0, r0, r1
	ldmfd sp!, {lr}
	b mapAB_

@------------------------------------
write1:
@------------------------------------
	tst addy, #1
	bne wa001

	strb_ r0, reg2
	ldrb_ r1, cartFlags
	tst r1, #SCREEN4
	bxne lr
	tst r0, #1
	b mirror2V_

wa001:
	bx lr
