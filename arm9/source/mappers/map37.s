;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper37init

	.struct mmc3Extra
outerPpuBank:	.byte 0
outerCpuBank:	.byte 0
cpuMask:		.byte 0

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Yet another MMC3 multicart.
;@ Used in:
;@ Super Mario Bros. + Tetris + Nintendo World Cup
mapper37init:
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
writel:			@($6000-$7FFF)
;@----------------------------------------------------------------------------
	;@ Check for WRAM enable (A001)
	ldrb_ r1,reg3
	and r1,r1,#0xC0
	cmp r1,#0x80			;@ Enabled and not write protected
	bxne lr
doWrite:
	and r2,r0,#4
	strb_ r2,outerPpuBank
	and r0,r0,#3
	cmp r0,#3
	orreq r2,r2,#2
	strb_ r2,outerCpuBank
	cmp r2,#4
	mov r1,#0x7
	moveq r1,#0xF
	strb_ r1,cpuMask

	ldrb_ r0,prg0
	and r0,r0,r1
	orr r0,r0,r2,lsl#2
	strb_ r0,prg0

	ldrb_ r0,prg1
	and r0,r0,r1
	orr r0,r0,r2,lsl#2
	strb_ r0,prg1

	mov r0,#-2
	and r0,r0,r1
	orr r0,r0,r2,lsl#2
	strb_ r0,prg2

	mov r0,#-1
	and r0,r0,r1
	orr r0,r0,r2,lsl#2
	strb_ r0,prg3

	ldrb_ r0,reg0
	eor r1,r0,#0xC0
	strb_ r1,reg0			;@ Force reload of banks
	b mmc3Mapping0W

;@----------------------------------------------------------------------------
write0:			@($8000-$9FFF)
;@----------------------------------------------------------------------------
	tst addy, #1
	beq mmc3Mapping0W

w8001:
	ldrb_ r1, reg0
	and r1, r1, #6
	cmp r1, #6				;@ PRG or CHR?
	ldrneb_ r1,outerPpuBank
	andne r0,r0,#0x7F		;@ CHR, one bank is 128Kb
	orrne r0,r0,r1,lsl#5
	ldreqb_ r1,cpuMask
	andeq r0,r0,r1			;@ PRG, one bank is 64/128Kb
	ldreqb_ r1,outerCpuBank
	orreq r0,r0,r1,lsl#2
	b mmc3Mapping1W
;@----------------------------------------------------------------------------
