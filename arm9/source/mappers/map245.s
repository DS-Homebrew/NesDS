;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper245init

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Waixing F003 board with MMC3 clone
;@ Used in:
;@ 勇者斗恶龙 VII - Dragon Quest (Yǒngzhě dòu è lóng VII - Dragon Quest),
mapper245init:
;@----------------------------------------------------------------------------
	.word write0, write1, rom_W, rom_W
	mov r0, #0
	str_ r0, reg0

	mov r0, #0x0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1
	
	mov r0, #0
	str_ r0, irq_enable

	bx lr

;@----------------------------------------------------------------------------
write0:				;@ 8000-9FFF
;@----------------------------------------------------------------------------
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

;@----------------------------------------------------------------------------
write1:				;@ A000-BFFF
;@----------------------------------------------------------------------------
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
