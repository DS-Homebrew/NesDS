;@----------------------------------------------------------------------------
	#include "mmc3.i"
;@----------------------------------------------------------------------------
	.global mapper74init

	.struct mmc3Extra
chr1:  .byte 0
chr3:  .byte 0

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
	.word write0, write1, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!, {lr}
	mov r0, #0
	str_ r0, reg0
	str_ r0, irq_latch

	mov r0, #0x0
	strb_ r0, prg0			;@ prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1
	bl mmc3SetBankCpu

	mov r0, #0
	strb_ r0, chr01
	mov r0, #2
	strb_ r0, chr23
	mov r0, #4
	strb_ r0, chr4
	mov r0, #5
	strb_ r0, chr5
	mov r0, #6
	strb_ r0, chr6
	mov r0, #7
	strb_ r0, chr7

	mov r0, #1
	strb_ r0, chr1
	mov r0, #3
	strb_ r0, chr3

	bl setbank_ppu

	ldr r0,=mmc3HSync
	str_ r0,scanlineHook

	adr r0, frameHook
	str_ r0,newFrameHook

	ldr r0,=VRAM_chr		;@ Enable chr write
	ldr r1,=vram_write_tbl
	mov r2,#8
	bl filler

	ldmfd sp!, {pc}
;@----------------------------------------------------------------------------
setbank_ppu:
;@----------------------------------------------------------------------------
	stmfd sp!, {lr}

	ldrb_ r0, reg0
	tst r0, #0x80
	beq 0f

	mov r1, #4
	ldrb_ r0, chr01
	bl chr1k
	mov r1, #5
	ldrb_ r0, chr1
	bl chr1k
	mov r1, #6
	ldrb_ r0, chr23
	bl chr1k
	mov r1, #7
	ldrb_ r0, chr3
	bl chr1k
	mov r1, #0
	ldrb_ r0, chr4
	bl chr1k
	mov r1, #1
	ldrb_ r0, chr5
	bl chr1k
	mov r1, #2
	ldrb_ r0, chr6
	bl chr1k
	mov r1, #3
	ldrb_ r0, chr7
	bl chr1k
	ldmfd sp!, {pc}

0:
	mov r1, #0
	ldrb_ r0, chr01
	bl chr1k
	mov r1, #1
	ldrb_ r0, chr1
	bl chr1k
	mov r1, #2
	ldrb_ r0, chr23
	bl chr1k
	mov r1, #3
	ldrb_ r0, chr3
	bl chr1k
	mov r1, #4
	ldrb_ r0, chr4
	bl chr1k
	mov r1, #5
	ldrb_ r0, chr5
	bl chr1k
	mov r1, #6
	ldrb_ r0, chr6
	bl chr1k
	mov r1, #7
	ldrb_ r0, chr7
	bl chr1k
	ldmfd sp!, {pc}

;@----------------------------------------------------------------------------
write0:				;@ 8000-9FFF
;@----------------------------------------------------------------------------
	tst addy, #1
	bne w8001

	strb_ r0, reg0
	stmfd sp!, {lr}
	bl mmc3SetBankCpu
	ldmfd sp!, {lr}
	b setbank_ppu

w8001:
	strb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #0xf
	cmp r1, #0x0c
	bxcs lr
	adrl_ r2, chr01
	strb r0, [r2, r1]
	cmp r1, #2
	addcc r2, r0, #1
	cmp r1, #0
	streqb_ r2, chr1
	cmp r1, #1
	streqb_ r2, chr3

	cmp r1, #6
	bcc setbank_ppu
	cmp r1, #0xa
	bcs setbank_ppu
	b mmc3SetBankCpu

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
frameHook:
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
