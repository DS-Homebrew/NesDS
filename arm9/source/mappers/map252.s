@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper252init
	latch = mapperData+0
	irqen = mapperData+1
	k4irq = mapperData+2
	counter = mapperData+3

	reg0	= mapperData+4
	reg1	= mapperData+5
	reg2	= mapperData+8
	reg3	= mapperData+9
	reg4	= mapperData+12
	reg5	= mapperData+13
	reg6	= mapperData+16
	reg7	= mapperData+17
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Waixing VRC4 clone
@ Used in: 三国志: 中原の覇者 (Sangokushi: Chūgen no Hasha)
@ See also mapper 253
mapper252init:
@---------------------------------------------------------------------------------
	.word write89, writeAB, writeCD, writeEF

	ldr r0, =0x0100
	str_ r0, reg0
	ldr r0, =0x0302
	str_ r0, reg2
	ldr r0, =0x0504
	str_ r0, reg4
	ldr r0, =0x0706
	str_ r0, reg6

	stmfd sp!, {lr}
	bl Konami_Init

	mov r0, #0
	bl chr01234567_

	ldr r0,=VRAM_chr		@enable/disable chr write
	ldr r1,=vram_write_tbl
	mov r2,#8
	bl filler

	adr r0, frameHook
	str_ r0, newFrameHook

	ldmfd sp!, {pc}

@--------------
write89:
	tst addy, #0x1000
	beq map89_
	bx lr

@---------------------------------------------------------------------------------
writeAB:
	tst addy, #0x1000	@addy=0xB***
	beq mapAB_

	and r0, r0, #0xF
	and r1, addy, #0xC
	mov r0, r0, lsl r1
	mov r2, #0xF
	mov r1, r2, lsl r1
	ldr_ r2, reg0
	bic r2, r2, r1
	orr r2, r2, r0
	str_ r2, reg0
	tst addy, #0x8
	movne r0, r2, lsr#8
	bne chr1_
	and r0, r2, #0xFF
	b chr0_

@---------------------------------------------------------------------------------
writeCD:
@---------------------------------------------------------------------------------
	tst addy, #0x1000	@addy=0xD***
	bne d0

	and r0, r0, #0xF
	and r1, addy, #0xC
	mov r0, r0, lsl r1
	mov r2, #0xF
	mov r1, r2, lsl r1
	ldr_ r2, reg2
	bic r2, r2, r1
	orr r2, r2, r0
	str_ r2, reg2
	tst addy, #0x8
	movne r0, r2, lsr#8
	bne chr3_
	and r0, r2, #0xFF
	b chr2_

d0:
	and r0, r0, #0xF
	and r1, addy, #0xC
	mov r0, r0, lsl r1
	mov r2, #0xF
	mov r1, r2, lsl r1
	ldr_ r2, reg4
	bic r2, r2, r1
	orr r2, r2, r0
	str_ r2, reg4
	tst addy, #0x8
	movne r0, r2, lsr#8
	bne chr5_
	and r0, r2, #0xFF
	b chr4_


@---------------------------------------------------------------------------------
writeEF:	
	tst addy, #0x1000	@addy=0xF***
	bne f0

	and r0, r0, #0xF
	and r1, addy, #0xC
	mov r0, r0, lsl r1
	mov r2, #0xF
	mov r1, r2, lsl r1
	ldr_ r2, reg6
	bic r2, r2, r1
	orr r2, r2, r0
	str_ r2, reg6
	tst addy, #0x8
	movne r0, r2, lsr#8
	bne chr7_
	and r0, r2, #0xFF
	b chr6_

f0:
	and r1, addy, #0xC
	ldr pc, [pc, r1]
	nop
	.word KoLatchLo, KoLatchHi, KoIRQEnable, KoIRQack

@------------------------
frameHook:
	mov r0,#-1
	ldr r1,=agb_obj_map
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4
	str r0,[r1],#4

	mov r0,#-1		@code from resetCHR
	ldr r1,=agb_bg_map
	mov r2,#16 * 2
	b filler
