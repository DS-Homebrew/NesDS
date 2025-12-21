;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper47init

	.struct mmc3Extra
bank_select:	.byte 0

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Yet another MMC3 multicart.
;@ Used in:
;@ Super Spike V'Ball + Nintendo World Cup
mapper47init:
;@----------------------------------------------------------------------------
	.word write0, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!, {lr}

	bl mmc3Init

	mov r0,#0
	bl doWrite

	adr r0, writel
	str_ r0, m6502WriteTbl+12

	ldmfd sp!, {lr}
	bx lr

;@----------------------------------------------------------------------------
writel:		@($6000-$7FFF)
;@----------------------------------------------------------------------------
	;@ Check for WRAM enable (A001)
	ldrb_ r1,reg3
	and r1,r1,#0xC0
	cmp r1,#0x80			;@ Enabled and not write protected
	bxne lr
doWrite:
	ands r0,r0,#1
	strb_ r0,bank_select

	ldrb_ r1,prg0
	and r1,r1,#0xF
	orr r1,r1,r0,lsl#4
	strb_ r1,prg0

	ldrb_ r1,prg1
	and r1,r1,#0xF
	orr r1,r1,r0,lsl#4
	strb_ r1,prg1

	mov r1,#0xE				;@ -2
	orr r1,r1,r0,lsl#4
	strb_ r1,prg2

	mov r1,#0xF				;@ -1
	orr r1,r1,r0,lsl#4
	strb_ r1,prg3

	ldrb_ r0,reg0
	eor r1,r0,#0xC0
	strb_ r1,reg0			;@ Force reload of banks
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
