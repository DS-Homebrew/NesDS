;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper118init

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC3 on TKSROM & TLSROM boards
;@ Used in:
;@ Armadillo
;@ Pro Sport Hockey
;@ Also see mapper 95, 158 & 207
mapper118init:
;@----------------------------------------------------------------------------
	.word write0, rom_W, mmc3CounterW, mmc3IrqEnableW
	b mmc3Init

;@----------------------------------------------------------------------------
write0:			;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy, #1
	beq mmc3MappingW

w8001:
	stmfd sp!, {lr}
	strb_ r0, reg1
	ldrb_ r1, reg0
	tst r1, #0x80
	and r1, r1, #7
	beq 0f
	cmp r1, #2
	bne 1f
	adr lr, 1f
	tst r0, #0x80
	b mirror1H_
0:
	cmp r1, #0
	bne 1f
	tst r0,#0x8
	bl mirror1H_
1:
	ldmfd sp!, {lr}
	ldrb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #7
	adrl_ r2, chr01
	strb r0, [r2, r1]
	cmp r1, #6
	bcc mmc3SetBankPpu
	b mmc3SetBankCpu
