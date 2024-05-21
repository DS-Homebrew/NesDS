@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper47init

	irq_latch	= mapperData+0
	irq_enable	= mapperData+1
	irq_reload	= mapperData+2
	irq_counter	= mapperData+3

	reg0 = mapperData+4
	reg1 = mapperData+5
	reg2 = mapperData+6
	reg3 = mapperData+7

	chr01 = mapperData+12
	chr23 = mapperData+13
	chr4  = mapperData+14
	chr5  = mapperData+15
	chr6  = mapperData+16
	chr7  = mapperData+17

	prg0  = mapperData+18
	prg1  = mapperData+19

	bank_select	= mapperData+26

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Yet another MMC3 multicart.
@ Used on:
@ Super Spike V'Ball + Nintendo World Cup
mapper47init:
@---------------------------------------------------------------------------------
	.word write0, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!, {lr}

	mov r0,#0x8
	str_ r0,prgSize16k
	mov r0, r0, lsl#1
	str_ r0,prgSize8k

	bl mapper4init+4*4

	adr r0, writel
	str_ r0, writemem_tbl+12

	ldmfd sp!, {lr}
	bx lr

@---------------------------------------------------------------------------------
writel:		@($6000-$7FFF)
@---------------------------------------------------------------------------------
	@ Add check for WRAM enable (A001)
	@ldrb_ r1,reg3
	@and r1,r1,#0xC0
	@cmp r1,#0x80			;@ Enabled and not write protected
	@bxne lr

	ands r0,r0,#1
	strb_ r0,bank_select
	moveq r1,#0x8
	movne r1,#0x10
	str_ r1,prgSize16k
	mov r1, r1, lsl#1
	str_ r1,prgSize8k

	ldrb_ r1,prg0
	and r1,r1,#0xF
	orr r1,r1,r0,lsl#4
	strb_ r1,prg0

	ldrb_ r1,prg1
	and r1,r1,#0xF
	orr r1,r1,r0,lsl#4
	strb_ r1,prg1

	ldrb_ r0,reg0
	ldr addy,=0x8000
	b mmc3MappingW

@------------------------------------
write0:
@------------------------------------
	tst addy, #1
	beq mmc3MappingW

w8001:
	ldrb_ r1, reg0
	and r1, r1, #6
	cmp r1, #6				;@ PRG or CHR?
	ldrb_ r1,bank_select
	andeq r0,r0,#0xF		;@ PRG, one bank is 128Kb
	orreq r0,r0,r1,lsl#4
	andne r0,r0,#0x7F		;@ CHR, one bank is 128Kb
	orrne r0,r0,r1,lsl#7
	b mmc3MappingW
@--------
