@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper74init
	.word write0, write1, write2, write3
	
	reg0 = mapperdata
	reg1 = mapperdata+1
	reg2 = mapperdata+2
	reg3 = mapperdata+3
	reg4 = mapperdata+4
	reg5 = mapperdata+5
	reg6 = mapperdata+6
	reg7 = mapperdata+7
	
	chr01 = mapperdata+8
	chr23 = mapperdata+9
	chr4  = mapperdata+10
	chr5  = mapperdata+11
	chr6  = mapperdata+12
	chr7  = mapperdata+13
	
	prg0  = mapperdata+14
	prg1  = mapperdata+15
	prg2  = mapperdata+16
	prg3  = mapperdata+17
	chr1  = mapperdata+18
	chr3  = mapperdata+19
	
	irq_enable	= mapperdata+20
	irq_counter	= mapperdata+21
	irq_latch	= mapperdata+22
	irq_request	= mapperdata+23
	patch		= mapperdata+24
	we_sram		= mapperdata+25
	irq_type	= mapperdata+26

	
@---------------------------------------------------------------------------------
mapper74init:
@---------------------------------------------------------------------------------
	.word write0, write1, write2, write3
	stmfd sp!, {lr}
	mov r0, #0
	str_ r0, reg0
	str_ r0, reg4
	
	mov r0, #0x0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
	mov r0, #1
	strb_ r0, prg1

	ldr_ r1, prgsize8k
	sub r0, r1, #2
	strb_ r0, prg2
	add r0, r0, #1
	strb_ r0, prg3
	
	bl setbank_cpu
	
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
	
	mov r0, #0
	str_ r0, irq_enable
	strb_ r0, patch
	strb_ r0, we_sram
	
	adr r0, hsync
	str_ r0,scanlinehook

	adr r0, framehook
	str_ r0,newframehook

	ldr r0,=VRAM_chr		@enable/disable chr write
	ldr r1,=vram_write_tbl		@ set the first 8 function pointers to 'void'?
	mov r2,#8
	bl filler

	ldmfd sp!, {pc}
@-------------------------------------------------------------------
setbank_cpu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}
	ldrb_ r0, reg0
	tst r0, #0x40
	beq sbc1
	
	ldrb_ r0, prg2
	bl map89_
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, prg0
	bl mapCD_
	ldmfd sp!, {lr}
	ldrb_ r0, prg3
	b mapEF_

sbc1:
	ldrb_ r0, prg0
	bl map89_
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, prg2
	bl mapCD_
	ldmfd sp!, {lr}
	ldrb_ r0, prg3
	b mapEF_
	

@-------------------------------------------------------------------
setbank_ppu:
@-------------------------------------------------------------------
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

@-------------------------------------------------------------------
hsync:
@-------------------------------------------------------------------
	ldr_ r0, scanline
	cmp r0, #240
	bcs hk
	
	ldrb_ r1, ppuctrl1
	tst r1, #0x18
	beq hk
	
	ldrb_ r1, irq_enable
	ands r1, r1, r1
	beq hk
	ldrb_ r1, irq_request
	ands r1, r1, r1
	bne hk
	
	ldrb_ r1, irq_counter
	cmp r0, #0
	bne cirq
	
	ands r1, r1, r1
	subne r1, r1, #1
cirq:
	subs r1, r1, #1
	strb_ r1, irq_counter
	bcs hk
	mov r0, #0xff
	strb_ r0, irq_request
	ldrb_ r0, irq_latch
	strb_ r0, irq_counter
	b CheckI
hk:
	fetch 0

@------------------------------------
write0:
@------------------------------------
	tst addy, #1
	bne w8001

	strb_ r0, reg0
	stmfd sp!, {lr}
	bl setbank_cpu
	bl setbank_ppu
	ldmfd sp!, {pc}

w8001:
	strb_ r0, reg1
	ldrb_ r1, reg0
	and r1, r1, #0xf
	cmp r1, #0x0c
	movcs pc, lr
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
	b setbank_cpu
	
@------------------------------------
write1:
@------------------------------------
	tst addy, #1
	bne wa001
	
	strb_ r0, reg2
	and r0, r0, #3
	cmp r0, #0
	beq mirror2V_
	cmp r0, #1
	beq mirror2H_
	cmp r0, #2
	b mirror1_

wa001:
	strb_ r0, reg3
	mov pc, lr
	
@------------------------------------
write2:
@------------------------------------
	tst addy, #1
	bne wc001
	
	strb_ r0, reg4
	strb_ r0, irq_counter
	mov r0, #0
	strb_ r0, irq_request
	mov pc, lr

wc001:
	strb_ r0, reg5
	strb_ r0, irq_latch
	mov r0, #0
	strb_ r0, irq_request
	mov pc, lr
	
@------------------------------------
write3:
@------------------------------------
	tst addy, #1
	bne we001
	
	strb_ r0, reg6
	mov r0, #0
	strb_ r0, irq_enable
	strb_ r0, irq_request
	mov pc, lr

we001:
	strb_ r0, reg7
	mov r0, #1
	strb_ r0, irq_enable
	mov r0, #0
	strb_ r0, irq_request
	mov pc, lr
	

@------------------------------------
framehook:
@------------------------------------
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
