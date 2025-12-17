;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper198init

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC3 plus more
mapper198init:
;@----------------------------------------------------------------------------
	.word write0, writeABCDEF, writeABCDEF, writeABCDEF
	stmfd sp!, {lr}

	bl mmc3Init

	bl setBankPPU

	adr r0, readl
	str_ r0, rp2A03MemRead
	adr r0, writel
	str_ r0, rp2A03MemWrite
/*
	adr r0, readh
	str_ r0, m6502ReadTbl+12
	adr r0, writeh
	str_ r0, m6502WriteTbl+12
*/
	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
writel:
;@----------------------------------------------------------------------------
	bic r1, addy, #0xE000
	ldr r2, =NES_XRAM
	strb r0, [r2, r1]
	bx lr
;@----------------------------------------------------------------------------
readl:
;@----------------------------------------------------------------------------
	bic r1, addy, #0xE000
	ldr r2, =NES_XRAM
	ldrb r0, [r2, r1]
	bx lr

;@----------------------------------------------------------------------------
writeh:
	ldr r1,=NES_SRAM
	bic r2, addy, #0xE000
	strb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
readh:
	ldr r1,=NES_SRAM	
	bic r2, addy, #0xE000
	ldrb r0,[r1,r2]
	bx lr
;@----------------------------------------------------------------------------
setBankPPU:
;@----------------------------------------------------------------------------
	ldr_ r1, vmemMask
	tst r1, #0x80000000
	bxne lr
	b mmc3SetBankPpu

;@----------------------------------------------------------------------------
write0:				;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy, #1
	bne w8001

	stmfd sp!, {lr}
	strb_ r0, reg0
	bl mmc3SetBankCpu
	ldmfd sp!, {lr}
	b setBankPPU

w8001:
	strb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #7
	cmp r1, #6
	bcs 6f

	adrl_ r2, chr01
	strb r0, [r2, r1]
	b setBankPPU
6:
	bne 7f
	cmp r0, #0x50
	andcs r0, r0, #0x4f
	strb_ r0, prg0
	b mmc3SetBankCpu
7:
	strb_ r0, prg1
	b mmc3SetBankCpu

;@----------------------------------------------------------------------------
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
