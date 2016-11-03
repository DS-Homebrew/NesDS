@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper253init
	.global debugwrite
	reg	= mapperdata+0
	reg0	= mapperdata+0
	reg1	= mapperdata+1
	reg2	= mapperdata+2
	reg3	= mapperdata+3
	reg4	= mapperdata+4
	reg5	= mapperdata+5
	reg6	= mapperdata+6
	reg7	= mapperdata+7
	irq_enable = mapperdata+16
	irq_counter= mapperdata+17
	irq_latch = mapperdata+18
	irq_clock = mapperdata+19
@---------------------------------------------------------------------------------
mapper253init:
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
	str_ r0, scanlinehook

	stmfd sp!, {lr}
	
	mov r0, #0
	bl chr01234567_

	ldr r0,=VRAM_chr				@enable/disable chr write
	ldr r1,=vram_write_tbl			@ set the first 8 function pointers to 'void'?
	mov r2,#8
	bl filler

	adr r0, framehook
	str_ r0, newframehook

	ldmfd sp!, {pc}

@--------------
write89:
	ldr r1, =0x8010
	cmp addy, r1
	beq map89_
	ldr r1, =0x9400
	cmp addy, r1
	movne pc, lr
	and r0, r0, #3
	tst r0, #2
	beq 0f
	tst r0, #1
	b mirror1_
0:
	tst r0, #1
	b mirror2V_

@---------------------------------------------------------------------------------
writeAB:
	ldr r1, =0xa010
	cmp r1, addy
	beq mapAB_
	tst addy, #0x1000
	moveq pc, lr

writeppu:
	mov r2, addy, lsr#12
	sub r2, r2, #0xb
	mov r2, r2, lsl#1
	tst addy, #0x8
	addne r2, r2, #1
	adrl_ r1, reg0
	tst addy, #0x4
	add addy, r1, r2
	ldrb r1, [addy]
	andeq r1, #0xF0
	andeq r0, #0xF
	orreq r0, r0, r1
	andne r1, #0xF
	orrne r0, r1, r0, lsl#4
	strb r0, [addy]
	mov r1, r2
	b chr1k

@---------------------------------------------------------------------------------
writeCD:	
	b writeppu
@---------------------------------------------------------------------------------
writeEF:	
	tst addy, #0x1000	@addy=0xF***
	beq writeppu

	and r1, addy, #0xc
	ldr pc, [pc, r1]
	mov r0, r0
	.word f000, f0004, f0008, void
f000:
	ldrb_ r1, irq_latch
	and r1, r1, #0xF0
	and r0, r0, #0xF
	orr r0, r1, r0
	strb_ r0, irq_latch
	mov pc, lr
f0004:
	ldrb_ r1, irq_latch
	and r1, r1, #0xF
	orr r0, r1, r0, lsl#4
	strb_ r0, irq_latch
f0008:
	strb_ r0, irq_enable
	tst r0, #2
	moveq pc, lr
	ldrb_ r1, irq_latch
	strb_ r1, irq_counter
	mov r0, #0
	strb_ r0, irq_clock
	mov pc, lr

@---------------------------------------------------------------------------------
hook:
	ldrb_ r0,ppuctrl1
	orr r0, r0, #0x18
	strb_ r0,ppuctrl1		@NOT let bg or sp to hide...

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
	b CheckI

hk0:
	fetch 0

@------------------------
framehook:
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
