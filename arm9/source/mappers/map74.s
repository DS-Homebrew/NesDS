;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper74init

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Waixing MMC3 clone on 43-393/43-406/860908C PCB
;@ Used in:
;@ 機甲戰士 (Jījiǎ Zhànshì, Chinese translation of Data East's Metal Max)
;@ 甲A - China Soccer League for Division A
;@ 第四次: 机器人大战 - Robot War IV
;@ 風雲 - Traitor Legend (original 1997 version)
mapper74init:
;@----------------------------------------------------------------------------
	.word mmc3MappingW, write1, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!, {lr}

	bl mmc3Init

	adr r0, frameHook
	str_ r0,newFrameHook

	ldr r0,=VRAM_chr		;@ Enable chr write
	ldr r1,=vram_write_tbl
	mov r2,#8
	bl filler

	ldmfd sp!, {pc}
;@----------------------------------------------------------------------------
write1:				;@ A000-BFFF
;@----------------------------------------------------------------------------
	tst addy, #1
	bne wa001

	strb_ r0, reg2
	and r0, r0, #3
	cmp r0, #2
	beq mirror1_
	tst r0, #1
	b mirror2V_

wa001:
	strb_ r0, reg3
	bx lr

;@----------------------------------------------------------------------------
frameHook:			;@ Used to refresh chr ram.
;@----------------------------------------------------------------------------
	mov r0,#-1
	ldr r1,=agb_obj_map
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4

	mov r0,#-1		;@ Code from resetCHR
	ldr r1,=agb_bg_map
	mov r2,#16 * 2
	b filler
