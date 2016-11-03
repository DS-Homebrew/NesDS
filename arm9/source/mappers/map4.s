@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
#define	MMC3_IRQ_KLAX		1
#define	MMC3_IRQ_SHOUGIMEIKAN	2
#define	MMC3_IRQ_DAI2JISUPER	3
#define	MMC3_IRQ_DBZ2		4
#define	MMC3_IRQ_ROCKMAN3	5
@---------------------------------------------------------------------------------
	.global mapper4init
	
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
	
	irq_enable	= mapperdata+16
	irq_counter	= mapperdata+17
	irq_latch	= mapperdata+18
	irq_request	= mapperdata+19
	vs_patch	= mapperdata+20
	vs_index	= mapperdata+21
	we_sram		= mapperdata+22
	irq_type	= mapperdata+23
	
	irq_preset	= mapperdata+24
	irq_preset_vbl	= mapperdata+25
	
@---------------------------------------------------------------------------------
mapper4init:
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
	
	bl setbank_ppu
	
	mov r0, #0
	str_ r0, irq_enable
	strb_ r0, irq_preset
	strb_ r0, irq_preset_vbl
	strb_ r0, irq_type
	strb_ r0, vs_patch
	strb_ r0, vs_index
	
	mov r0, #0xFF
	strb_ r0, irq_latch
	
	
	ldr r0,=hsync
	str_ r0,scanlinehook
	adr r0, writel
	str_ r0, writemem_tbl+8
	adr r0, readl
	str_ r0, readmem_tbl+8

	mov pc, lr
	
@patch for games...
	@mov r0, #0		@init val
	@ldr_ r1, rombase	@src
	@ldr_ r2, romsize8k	@size
	@mov r2, r2, lsl#13
	@swi 0x0e0000		@swicrc16
	
	@ldr r1, =0x5807		@Tenchi o Kurau 2 - Akakabe no Tatakai Chinese Edtion.
	@cmp r1, r0
	@ldreq_ r2, emuflags
	@orreq r2, r2, #PALTIMING
	@streq_ r2, emuflags

	@mov pc, lr

@---------------------------------------------------------------------------------
writel:		@($4100-$5FFF)
@---------------------------------------------------------------------------------
	cmp addy, #0x5000
	bcc IO_W
	sub r2, addy, #0x4000
	ldr r1, =NES_XRAM
	strb r0, [r1, r2]
	mov pc, lr

@---------------------------------------------------------------------------------
readl:		@($4100-$5FFF)
@---------------------------------------------------------------------------------
	cmp addy, #0x5000
	bcc IO_R
	sub r2, addy, #0x4000
	ldr r1, =NES_XRAM
	ldrb r0, [r1, r2]
	mov pc, lr
@-------------------------------------------------------------------
setbank_cpu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}
	ldrb_ r0, reg0
	tst r0, #0x40
	beq sbc1
	
	mov r0, #-2
	bl map89_
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, prg0
	bl mapCD_
	mov r0, #-1
	bl mapEF_
	b cend

sbc1:
	ldrb_ r0, prg0
	bl map89_
	ldrb_ r0, prg1
	bl mapAB_
	mov r0, #-1
	bl mapCDEF_

cend:
	ldmfd sp!, {pc}

@-------------------------------------------------------------------
setbank_ppu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}

	ldrb_ r0, reg0
	tst r0, #0x80
	beq 0f
	
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
	mov r1, #4
	ldrb_ r0, chr01
	bl chr1k
	mov r1, #5
	ldrb_ r0, chr01
	add r0, r0, #1
	bl chr1k
	mov r1, #6
	ldrb_ r0, chr23
	bl chr1k
	mov r1, #7
	ldrb_ r0, chr23
	add r0, r0, #1
	bl chr1k
	ldmfd sp!, {pc}
	
0:
	mov r1, #0
	ldrb_ r0, chr01
	bl chr1k
	mov r1, #1
	ldrb_ r0, chr01
	add r0, r0, #1
	bl chr1k
	mov r1, #2
	ldrb_ r0, chr23
	bl chr1k
	mov r1, #3
	ldrb_ r0, chr23
	add r0, r0, #1
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
	and r1, r1, #7
	cmp r1, #2
	andcc r0, r0, #0xfe
	adrl_ r2, chr01
	strb r0, [r2, r1]
	cmp r1, #6
	bcc setbank_ppu
	b setbank_cpu
	
@------------------------------------
write1:
@------------------------------------
	tst addy, #1
	bne wa001
	
	strb_ r0, reg2
	ldrb_ r1, cartflags
	tst r1, #SCREEN4
	movne pc, lr
	tst r0, #1
	b mirror2V_

wa001:
	strb_ r0, reg3
	mov pc, lr
	
@------------------------------------
write2:
@------------------------------------
	tst addy, #1
	bne wc001
	
	strb_ r0, reg4
	ldrb_ r1, irq_type
	cmp r1, #MMC3_IRQ_KLAX
	cmpne r1, #MMC3_IRQ_ROCKMAN3
	streqb_ r0, irq_counter
	strneb_ r0, irq_latch
	cmp r1, #MMC3_IRQ_DBZ2
	moveq r0, #7
	streqb_ r0, irq_latch
	mov pc, lr

wc001:
	strb_ r0, reg5
	ldrb_ r1, irq_type
	cmp r1, #MMC3_IRQ_KLAX
	cmpne r1, #MMC3_IRQ_ROCKMAN3
	streqb_ r0, irq_latch
	moveq pc, lr
	
	ldrb_ r0, irq_counter
	orr r0, r0, #0x80
	strb_ r0, irq_counter
	
	mov r2, #0xFF
	ldr_ r0, scanline
	cmp r0, #240
	strccb_ r2, irq_preset
	movcc pc, lr
	
	cmp r1, #MMC3_IRQ_SHOUGIMEIKAN
	streqb_ r2, irq_preset
	moveq pc, lr
	
	strb_ r2, irq_preset_vbl
	mov r0, #0
	strb_ r0, irq_preset
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

@-------------------------------------------------------------------
hsync:
@-------------------------------------------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuctrl1
	ldrb_ r2, irq_type
	cmp r2, #MMC3_IRQ_KLAX
	bne skip1
	
	cmp r0, #240
	bcs 0f
	tst r1, #0x18
	beq 0f
	
	ldrb_ r0, irq_enable
	ands r0, r0, r0
	beq 0f
	
	ldrb_ r2, irq_counter
	cmp r2, #0
	bne 1f

	ldrb_ r2, irq_latch
	strb_ r2, irq_counter
	mov r0, #0xFF
	strb_ r0, irq_request
1:	
	ldrb_ r2, irq_latch
	cmp r2, #0
	subhi r2, r2, #1
	strb_ r2, irq_counter
0:
	ldrb_ r0, irq_request
	ands r0, r0, r0
	beq hq

	b CheckI
@--------
skip1:
	cmp r2, #MMC3_IRQ_ROCKMAN3
	bne skip2
	cmp r0, #240
	bcs 0f
	tst r1, #0x18
	beq 0f
	
	ldrb_ r0, irq_enable
	ands r0, r0, r0
	beq 0f

	ldrb_ r2, irq_counter
	subs r2, r2, #1
	strb_ r2, irq_counter
	bne 0f
	
	mov r0, #0xff
	strb_ r0, irq_request
	ldrb_ r0, irq_latch
	strb_ r0, irq_counter
	
0:
	ldrb_ r0, irq_request
	ands r0, r0, r0
	beq hq
	b CheckI
@--------
skip2:
	cmp r0, #240
	bcs hq
	tst r1, #0x18
	beq hq
	
	mov r2, #0
	ldrb_ r1, irq_preset_vbl
	ands r1, r1, r1
	ldrneb_ r1, irq_latch
	strneb_ r1, irq_counter
	strneb_ r2, irq_preset_vbl
	
	ldrb_ r1, irq_preset
	ands r1, r1, r1
	beq 0f
	
	ldrb_ r1, irq_latch
	strb_ r1, irq_counter
	strb_ r2, irq_preset
	
	ldrb_ r2, irq_type
	cmp r2, #MMC3_IRQ_DAI2JISUPER
	cmpeq r0, #0
	subeq r1, r1, #1
	@streqb_ r1, irq_counter
	b 1f
	
0:
	ldrb_ r1, irq_counter
	subs r1, r1, #1
	movcc r1, #0
1:
	strb_ r1, irq_counter
	ands r1, r1, r1
	bne hq
	
	mov r2, #0xFF
	strb_ r2, irq_preset
	
	ldrb_ r1, irq_enable
	ands r1, r1, r1
	strneb_ r2, irq_request
	bne CheckI
hq:
	fetch 0
