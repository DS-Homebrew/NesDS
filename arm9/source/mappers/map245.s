@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper245init
	
	reg0 = mapperdata
	reg1 = mapperdata+1
	reg2 = mapperdata+2
	reg3 = mapperdata+3
	reg4 = mapperdata+4
	reg5 = mapperdata+5
	reg6 = mapperdata+6
	reg7 = mapperdata+7
	
	chr01 = mapperdata+8
	chr23 = mapperdata+9
	chr4  = mapperdata+10
	chr5  = mapperdata+11
	chr6  = mapperdata+12
	chr7  = mapperdata+13
	
	prg0  = mapperdata+14
	prg1  = mapperdata+15
	
	irq_enable	= mapperdata+16
	irq_counter	= mapperdata+17
	irq_latch	= mapperdata+18
	irq_request	= mapperdata+19
	we_sram		= mapperdata+20
	irq_type	= mapperdata+21
	
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

	mov pc, lr

@------------------------------------
write0:
@------------------------------------
	tst addy, #1
	bne w8001

	strb_ r0, reg0
	mov pc, lr

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
	ldrb_ r1, cartflags
	tst r1, #SCREEN4
	movne pc, lr
	tst r0, #1
	b mirror2V_

wa001:
	mov pc, lr