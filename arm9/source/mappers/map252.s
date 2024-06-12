@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper252init
	reg	= mapperData+0
	reg0	= mapperData+0
	reg1	= mapperData+1
	reg2	= mapperData+4
	reg3	= mapperData+5
	reg4	= mapperData+8
	reg5	= mapperData+9
	reg6	= mapperData+12
	reg7	= mapperData+13
	irq_enable = mapperData+16
	irq_counter= mapperData+17
	irq_latch = mapperData+18
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
	str_ r0, reg
	ldr r0, =0x0302
	str_ r0, reg + 4
	ldr r0, =0x0504
	str_ r0, reg + 8
	ldr r0, =0x0706
	str_ r0, reg + 12

	adr r0, hook
	str_ r0, scanlineHook

	stmfd sp!, {lr}

	mov r0, #0
	bl chr01234567_

	ldr r0,=VRAM_chr			@ enable/disable chr write
	ldr r1,=vram_write_tbl		@ set the first 8 function pointers to 'void'?
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
	and r0, r0, r0		@a nop
	.word w0, w1, w2, w3
w0:
	ldrb_ r1, irq_latch
	and r0, r0, #0xF
	bic r1, r1, #0xF
	orr r1, r1, r0
	strb_ r1, irq_latch
	bx lr
w1:
	ldrb_ r1, irq_latch
	and r0, r0, #0xF
	bic r1, r1, #0xF0
	orr r1, r1, r0, lsl#4
	strb_ r1, irq_latch
	bx lr
w2:
	and r0, r0, #3
	strb_ r0, irq_enable
	tst r0, #2
	bxeq lr
	ldrb_ r1, irq_latch
	strb_ r1, irq_counter
	bx lr
w3:
	ldrb_ r0, irq_enable
	ands r0, r0, #1
	movne r0, #3
	strb_ r0, irq_enable
	bx lr

@---------------------------------------------------------------------------------
hook:
	ldrb_ r0,ppuCtrl1
	orr r0, r0, #0x18
	strb_ r0,ppuCtrl1		@NOT let bg or sp to hide...

	ldrb_ r0, irq_enable
	tst r0, #2
	beq hk0

	ldrb_ r1, irq_counter
	add r1, r1, #1
	tst r1, #0xFF
	strneb_ r1, irq_counter
	bne hk0

	tst r0, #1
	moveq r0, #0
	strb_ r0, irq_enable
	ldrb_ r1, irq_latch
	strb_ r1, irq_counter
	mov r0,#1
	b rp2A03SetIRQPin

hk0:
	fetch 0

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
