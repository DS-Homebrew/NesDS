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

	mov r0,#0
	strb_ r0,outerPpuBank
	strb_ r0,outerCpuBank
	mov r0,#0x7
	strb_ r0,cpuMask
	mov r0,#0x04
	str_ r0,prgSize16k
	mov r0, r0, lsl#1
	str_ r0,prgSize8k

	bl mmc3Init

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

	and r2,r0,#4
	strb_ r2,outerPpuBank
	and r0,r0,#3
	cmp r0,#3
	orreq r2,r2,#2
	strb_ r2,outerCpuBank
	cmp r2,#2
	mov r1,#0x7
	movhi r1,#0xF
	strb_ r1,cpuMask
	movmi r0,#0x04
	moveq r0,#0x08
	movhi r0,#0x10
	str_ r0,prgSize16k
	mov r0, r0, lsl#1
	str_ r0,prgSize8k

	ldrb_ r0,prg0
	and r0,r0,r1
	orr r0,r0,r2,lsl#2
	strb_ r0,prg0

	ldrb_ r0,prg1
	and r0,r0,r1
	orr r0,r0,r2,lsl#2
	strb_ r0,prg1

	ldrb_ r0,reg0
	ldr addy,=0x8000
	b mmc3MappingW

;@----------------------------------------------------------------------------
write0:			@($8000-$9FFF)
;@----------------------------------------------------------------------------
	tst addy, #1
	beq mmc3MappingW

w8001:
	ldrb_ r1, reg0
	and r1, r1, #6
	cmp r1, #6				;@ PRG or CHR?
	ldrneb_ r1,outerPpuBank
	andne r0,r0,#0x7F		;@ CHR, one bank is 128Kb
	orrne r0,r0,r1,lsl#5
	ldreqb_ r1,cpuMask
	andeq r0,r0,r1			;@ PRG, one bank is 128Kb
	ldreqb_ r1,outerCpuBank
	orreq r0,r0,r1,lsl#2
	b mmc3MappingW
;@----------------------------------------------------------------------------
