@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------	
	.global mapper90init
	irq_latch = mapperdata
	irq_occur = mapperdata + 1
	irq_enable = mapperdata + 2
	irq_counter = mapperdata + 3
	irq_preset = mapperdata + 4
	irq_offset	= mapperdata + 5		@shoud be fixed???

	prg_6000	= mapperdata + 8
	prg_E000	= mapperdata + 9
	prg_size	= mapperdata + 10
	chr_size	= mapperdata + 11

	mir_mode	= mapperdata + 12
	mir_type	= mapperdata + 13

	key_val		= mapperdata + 16
	mul_val1	= mapperdata + 17
	mul_val2	= mapperdata + 18

	mul_ret		= mapperdata + 20

	prg_reg0	= mapperdata + 24
	prg_reg1	= mapperdata + 25
	prg_reg2	= mapperdata + 26
	prg_reg3	= mapperdata + 27

	ch_reg0		= mapperdata + 32
	ch_reg1		= mapperdata + 36
	ch_reg2		= mapperdata + 40
	ch_reg3		= mapperdata + 44
	ch_reg4		= mapperdata + 48
	ch_reg5		= mapperdata + 52
	ch_reg6		= mapperdata + 56
	ch_reg7		= mapperdata + 60

	nt_reg0		= mapperdata + 64
	nt_reg1		= mapperdata + 68
	nt_reg2		= mapperdata + 72
	nt_reg3		= mapperdata + 76

	patch		= mapperdata + 80

@---------------------------------------------------------------------------------
mapper90init:
@---------------------------------------------------------------------------------
	.word write89,writeAB,writeCD,void

	stmfd sp!, {lr}

	ldr_ r0, prgsize8k
	sub r0, r0, #1
	strb_ r0, prg_reg3
	sub r0, r0, #1
	strb_ r0, prg_reg2
	sub r0, r0, #1
	strb_ r0, prg_reg1
	sub r0, r0, #1
	strb_ r0, prg_reg0

	mov r0, #-1
	bl map89ABCDEF_

	mov r0, #0
	bl chr01234567_

	mov r0, #0
	adrl_ r1, ch_reg0
	adrl_ r2, nt_reg0
0:
	str r0, [r1], #4
	cmp r0, #4
	strcc r0, [r2], #4
	add r0, r0, #1
	cmp r0, #8
	bne 0b

	ldrb r0, sw_val
	eor r0, r0, #0xFF
	strb r0, sw_val			@for multi-in-one switch.

	adr r1, readl
	str_ r1,readmem_tbl+8
	adr r1,writel
	str_ r1,writemem_tbl+8

	ldr r0,=hbhook
	str_ r0,scanlinehook

	ldr_ r0, prgcrc
	ldr r1, =0x9A36
	cmp r0, r1
	streqb_ r0, patch

	ldmfd sp!, {pc}
@--------------
sw_val:
	.word 0

@---------------------------------------------------------------------------------
writel:
@---------------------------------------------------------------------------------
	cmp addy,#0x5000
	blo IO_W
	ldr r1, =0x5803
	cmp addy, r1
	streqb_ r0, key_val
	moveq pc, lr

	ldr r1, =0x5800
	cmp addy, r1
	movcc pc, lr
	add r1, r1, #2
	cmp addy, r1
	movcs pc, lr

	tst addy, #0x1
	streqb_ r0, mul_val1
	strneb_ r0, mul_val2

	ldrb_ r0, mul_val1
	ldrb_ r1, mul_val2
	mov r2, #0
	
	tst r0, #0x1
	addne r2, r2, r1
	tst r0, #0x2
	addne r2, r2, r1, lsl#1
	tst r0, #0x4
	addne r2, r2, r1, lsl#2
	tst r0, #0x8
	addne r2, r2, r1, lsl#3
	tst r0, #0x10
	addne r2, r2, r1, lsl#4
	tst r0, #0x20
	addne r2, r2, r1, lsl#5
	tst r0, #0x40
	addne r2, r2, r1, lsl#6
	tst r0, #0x80
	addne r2, r2, r1, lsl#7

	str_ r2, mul_ret
	mov pc, lr
@---------------------------------------------------------------------------------
readl:
@---------------------------------------------------------------------------------
	cmp addy,#0x5000
	blo IO_R
	ldreqb r0, sw_val
	eoreq r0, r0, #0xFF
	moveq pc, lr
	ldr r1, =0x5800
	cmp addy, r1
	ldreqb_ r0, mul_ret
	moveq pc, lr
	ldr r1, =0x5801
	cmp addy, r1
	ldreqb_ r0, mul_ret + 1
	moveq pc, lr
	ldr r1, =0x5803
	cmp addy, r1
	ldreqb_ r0, key_val
	moveq pc, lr

	mov r0, addy, lsr#8
	mov pc, lr

@---------------------------------------------------------------------------------
write89:
@---------------------------------------------------------------------------------
	tst addy, #0x1000
	bne 0f

	and addy, addy, #7
	cmp addy, #4
	movcs pc, lr

	adrl_ r1, prg_reg0
	strb r0, [r1, addy]
	b setbank_cpu

0:
	and addy, addy, #7
	adrl_ r1, ch_reg0
	strb r0, [r1, addy, lsl#2]
	b setbank_ppu

@---------------------------------------------------------------------------------
writeAB:
@---------------------------------------------------------------------------------
	tst addy, #0x1000
	bne 0f

	and addy, addy, #7
	adrl_ r1, ch_reg0 + 1
	strb r0, [r1, addy, lsl#2]
	b setbank_ppu

0:
	tst addy, #0x4
	and addy, addy, #3
	adrl_ r1, nt_reg0
	addne r1, r1, #1
	strb r0, [r1, addy, lsl#2]
	b setbank_vram
@---------------------------------------------------------------------------------
writeCD:
@---------------------------------------------------------------------------------
	tst addy, #0x1000
	bne wd000

	and r2, addy, #7
	adr r1, ctable
	ldr pc, [r1, r2, lsl#2]
	and r0, r0, r0
@-----------------
ctable:
	.word void, void, wc002, wc003, void, wc005, wc006, void
@-----------------
wc002:
	mov r0, #0
	@strb_ r0, irq_enable					@this instruction does not work well...
	strb_ r0, irq_occur
	mov pc, lr
wc003:
	mov r0, #0xFF
	strb_ r0, irq_enable
	strb_ r0, irq_preset
	mov pc, lr
wc005:
	ldrb_ r1, irq_offset
	tst r1, #0x80
	orrne r1, r1, r1
	eorne r0, r0, r1
	strneb_ r0, irq_latch
	andeq r1, r1, #0x27
	orreq r0, r0, r1
	streqb_ r0, irq_latch
	mov r0, #0xFF
	strb_ r0, irq_preset
	mov pc, lr
wc006:
	ldrb_ r1, patch
	ands r1, r1, r1
	moveq pc, lr
	strb_ r0, irq_offset
	mov pc, lr
@-----------------
wd000:
	and addy, addy, #0x7
	cmp addy, #1
	movhi pc, lr
	andeq r0, r0, #3
	streqb_ r0, mir_type
	beq setbank_vram

	stmfd sp!, {lr}
	and r1, r0, #0x80
	strb_ r1, prg_6000
	and r1, r0, #0x4
	strb_ r1, prg_E000
	and r1, r0, #0x3
	strb_ r1, prg_size

	and r1, r0, #0x18
	mov r1, r1, lsr#3
	strb_ r1, chr_size

	and r1, r0, #0x20
	strb_ r1, mir_mode

	bl setbank_cpu
	bl setbank_ppu
	ldmfd sp!, {lr}
	b setbank_vram

@--------------------------------
setbank_cpu:
	ldrb_ r0, prg_size
	adr r1, cputable
	ldr pc, [r1, r0, lsl#2]
	and r0, r0, r0

cputable:
	.word prgset0, prgset1, prgset2, prgset3
@---------------
prgset0:
	mov r0, #-1
	b map89ABCDEF_
prgset1:
	stmfd sp!, {lr}
	ldrb_ r0, prg_reg1
	bl map89AB_
	mov r0, #-1
	ldmfd sp!, {lr}
	b mapCDEF_
prgset2:
	stmfd sp!, {lr}
	ldrb_ r0, prg_reg0
	bl map89_
	ldrb_ r0, prg_reg1
	bl mapAB_
	ldrb_ r0, prg_reg2
	bl mapCD_
	ldmfd sp!, {lr}
	ldrb_ r0, prg_E000
	ands r0, r0, r0
	ldrb_ r0, prg_reg3
	b mapEF_

	stmfd sp!, {lr}
	mov r0, #-1
	bl mapEF_
	ldmfd sp!, {lr}
	ldrb_ r0, prg_6000
	ands r0, r0, r0
	ldrneb_ r0, prg_reg3
	bne map67_
	mov pc, lr
prgset3:
	stmfd sp!, {lr}
	ldrb_ r0, prg_reg3
	bl map89_
	ldrb_ r0, prg_reg2
	bl mapAB_
	ldrb_ r0, prg_reg1
	bl mapCD_
	ldrb_ r0, prg_reg0
	bl mapEF_
	ldmfd sp!, {pc}

@--------------------------------
setbank_ppu:
	ldrb_ r0, chr_size
	adr r1, pputable
	ldr pc, [r1, r0, lsl#2]
	and r0, r0, r0

pputable:
	.word chrset0, chrset1, chrset2, chrset3
@---------------
chrset0:
	ldr_ r0, ch_reg0
	b chr01234567_			@two bytes.... e....
chrset1:
	stmfd sp!, {lr}
	ldr_ r0, ch_reg0
	bl chr0123_
	ldr_ r0, ch_reg4
	ldmfd sp!, {lr}
	b chr4567_
chrset2:
	stmfd sp!, {lr}
	ldr_ r0, ch_reg0
	bl chr01_
	ldr_ r0, ch_reg2
	bl chr23_
	ldr_ r0, ch_reg4
	bl chr45_
	ldr_ r0, ch_reg6
	bl chr67_
	ldmfd sp!, {pc}
chrset3:
	stmfd sp!, {lr}
	ldr_ r0, ch_reg0
	bl chr0_
	ldr_ r0, ch_reg1
	bl chr1_
	ldr_ r0, ch_reg2
	bl chr2_
	ldr_ r0, ch_reg3
	bl chr3_
	ldr_ r0, ch_reg4
	bl chr4_
	ldr_ r0, ch_reg5
	bl chr5_
	ldr_ r0, ch_reg6
	bl chr6_
	ldr_ r0, ch_reg7
	bl chr7_
	ldmfd sp!, {pc}


@--------------------------------
setbank_vram:
	ldrb_ r1, patch
	ands r1, r1, r1
	bne 1f

	ldrb_ r0, mir_mode
	ands r0, r0, r0
	bne vromnt
1:
	ldrb_ r0, mir_type
	cmp r0, #0
	beq mirror2V_
	cmp r0, #1
	beq mirror2H_
	b mirror1H_			@this is correct...

vromnt:

	ldr_ r0, nt_reg0
	cmp r0, #0
	beq 0f
	ldr_ r0, nt_reg1
	cmp r0, #1
	beq 0f
	ldr_ r0, nt_reg2
	cmp r0, #2
	beq 0f
	ldr_ r0, nt_reg3
	cmp r0, #3
0:
	moveq r0, #0
	streqb_ r0, mir_mode
	moveq pc, lr

	stmfd sp!, {lr}
	ldr_ r0, nt_reg0
	mov r1, #0
	bl vromnt1k
	ldr_ r0, nt_reg1
	mov r1, #1
	bl vromnt1k
	ldr_ r0, nt_reg2
	mov r1, #2
	bl vromnt1k
	ldr_ r0, nt_reg3
	mov r1, #3
	bl vromnt1k

	mov r0, #0x1C00
	add r0, r0, #0xc000
	str_ r0, bg0cnt

	ldmfd sp!, {pc}

@--------------------------------
hbhook:
@--------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuctrl1
	cmp r0, #240
	bcs hk0
	tst r1, #0x18
	beq hk0

	ldrb_ r0, irq_counter
	ldrb_ r1, irq_preset
	ands r1, r1, r1
	movne r2, #0
	strneb_ r2, irq_preset
	ldrneb_ r0, irq_latch
	strneb_ r0, irq_counter

	subs r0, r0, #0x1
	strcsb_ r0, irq_counter

	bhi hk0

	ldrb_ r0, irq_enable
	ands r0, r0, r0
	bne CheckI

hk0:
	fetch 0