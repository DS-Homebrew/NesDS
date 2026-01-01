;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper45init

	.struct mmc3Extra
regSelect:		.byte 0
chrOR:			.byte 0
prgOR:			.byte 0
chrAND:			.byte 0
prgAND:			.byte 0
bank_select:	.byte 0

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Multicart PCBs using the GA23C ASIC in its standard configuration
;@ Used in:
;@ Brain Series 12-in-1
;@ Super 3-in-1 Multicart K3M07
;@ Super 4-in-1 Multicart K4003
;@ Super 4-in-1 Multicart K4076
;@ Super 4-in-1 Multicart K4086
;@ Super HIK 4-in-1 Multicart S4020
;@ Super HIK 7-in-1 Multicart K7006
mapper45init:
;@----------------------------------------------------------------------------
	.word write0, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!, {lr}

	mov r0,#0x8
	str_ r0,prgSize16k
	mov r0, r0, lsl#1
	str_ r0,prgSize8k

	bl mmc3Init

	adr r0, writel
	str_ r0, m6502WriteTbl+12

	ldmfd sp!, {lr}
	bx lr

;@----------------------------------------------------------------------------
writel:		@($6000-$7FFF)
;@----------------------------------------------------------------------------
	tst addy,#0x1000
	bxne lr

	tst addy,#0x0001		;@ 6001?
	movne r0,#0
	strneb_ r0,regSelect	;@ Reset reg select
	bxne lr

	ldrb_ r1,regSelect
	add r2,r1,#1
	and r2,r2,#3
	strb_ r2,regSelect

	adrl_ r2,chrOR
	strb r0,[r2,r1]

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
	b mmc3Mapping0W

;@----------------------------------------------------------------------------
write0:
;@----------------------------------------------------------------------------
	tst addy, #1
	beq mmc3Mapping0W

w8001:
	ldrb_ r1, reg0
	and r1, r1, #6
	cmp r1, #6				;@ PRG or CHR?
	ldrb_ r1,bank_select
	andeq r0,r0,#0xF		;@ PRG, one bank is 128Kb
	orreq r0,r0,r1,lsl#4
	andne r0,r0,#0x7F		;@ CHR, one bank is 128Kb
	orrne r0,r0,r1,lsl#7
	b mmc3Mapping1W
;@----------------------------------------------------------------------------
