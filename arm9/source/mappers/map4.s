@---------------------------------------------------------------------------------
	#include "equates.h"
#define	MMC3_IRQ_KLAX		1
#define	MMC3_IRQ_SHOUGIMEIKAN	2
#define	MMC3_IRQ_DAI2JISUPER	3
#define	MMC3_IRQ_DBZ2		4
#define	MMC3_IRQ_ROCKMAN3	5
@---------------------------------------------------------------------------------
	.global mapper4init
	.global mmc3SetBankCpu
	.global mmc3MappingW
	.global mmc3MirrorW
	.global mmc3CounterW
	.global mmc3IrqEnableW
	.global mmc3HSync

	irq_latch	= mapperData+0
	irq_enable	= mapperData+1
	irq_reload	= mapperData+2
	irq_counter	= mapperData+3

	reg0 = mapperData+4
	reg1 = mapperData+5
	reg2 = mapperData+6
	reg3 = mapperData+7
	reg4 = mapperData+8
	reg5 = mapperData+9
	reg6 = mapperData+10
	reg7 = mapperData+11

	chr01 = mapperData+12
	chr23 = mapperData+13
	chr4  = mapperData+14
	chr5  = mapperData+15
	chr6  = mapperData+16
	chr7  = mapperData+17

	prg0  = mapperData+18
	prg1  = mapperData+19

	vs_patch	= mapperData+20
	vs_index	= mapperData+21
	we_sram		= mapperData+22
	irq_type	= mapperData+23

	irq_request	= mapperData+24

@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ MMC3
mapper4init:
@---------------------------------------------------------------------------------
	.word mmc3MappingW, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW
	stmfd sp!, {lr}
	mov r0, #0
	str_ r0, reg0
	str_ r0, reg4

	mov r0, #0x0
	strb_ r0, prg0			@prg0 = 0; prg1 = 1
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

	bl setbank_ppu

	mov r0, #0
	str_ r0, irq_enable
	strb_ r0, irq_reload
	strb_ r0, irq_type
	strb_ r0, vs_patch
	strb_ r0, vs_index

	mov r0, #0xFF
	strb_ r0, irq_latch

	ldr r0,=mmc3HSync
	str_ r0,scanlineHook
	adr r0, writel
	str_ r0, rp2A03MemWrite
	adr r0, readl
	str_ r0, rp2A03MemRead

	ldmfd sp!, {lr}
	bx lr

@patch for games...
	@ldrb_ r0, irq_type
	@cmp r0, #MMC3_IRQ_KLAX
	@ldreq r2,=hSyncRAMBO1
	@cmp r0, #MMC3_IRQ_ROCKMAN3
	@ldreq r2,=hSyncRockman3
	@cmp r2, #MMC3_IRQ_DAI2JISUPER
	@ldreq r2,=mmc3HSync___
	@str_ r2,scanlineHook

	@mov r0, #0		@init val
	@ldr_ r1, romBase	@src
	@ldr_ r2, romSize8k	@size
	@mov r2, r2, lsl#13
	@swi 0x0e0000		@swicrc16

	@ldr r1, =0x5807		@Tenchi o Kurau 2 - Akakabe no Tatakai Chinese Edtion.
	@cmp r1, r0
	@ldreq_ r2, emuFlags
	@orreq r2, r2, #PALTIMING
	@streq_ r2, emuFlags

	@bx lr

@---------------------------------------------------------------------------------
writel:		@($4020-$5FFF)
@---------------------------------------------------------------------------------
	cmp addy, #0x5000
	bcc empty_W
	sub r2, addy, #0x4000
	ldr r1, =NES_XRAM
	strb r0, [r1, r2]
	bx lr

@---------------------------------------------------------------------------------
readl:		@($4100-$5FFF)
@---------------------------------------------------------------------------------
	cmp addy, #0x5000
	bcc empty_R
	sub r2, addy, #0x4000
	ldr r1, =NES_XRAM
	ldrb r0, [r1, r2]
	bx lr
@-------------------------------------------------------------------
mmc3SetBankCpu:
@-------------------------------------------------------------------
	stmfd sp!, {lr}
	ldrb_ r0, prg1
	bl mapAB_
	ldrb_ r0, reg0
	tst r0, #0x40
	beq sbc1

	mov r0, #-2
	bl map89_
	ldrb_ r0, prg0
	bl mapCD_
	ldmfd sp!, {lr}
	mov r0, #-1
	b mapEF_

sbc1:
	ldrb_ r0, prg0
	bl map89_
	ldmfd sp!, {lr}
	mov r0, #-1
	b mapCDEF_

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
	mov r0,r0,lsr#1
	bl chr2k
	mov r1, #6
	ldrb_ r0, chr23
	mov r0,r0,lsr#1
	bl chr2k
	ldmfd sp!, {pc}

0:
	mov r1, #0
	ldrb_ r0, chr01
	mov r0,r0,lsr#1
	bl chr2k
	mov r1, #2
	ldrb_ r0, chr23
	mov r0,r0,lsr#1
	bl chr2k
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
mmc3MappingW:
@------------------------------------
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
	and r1, r1, #7
	adrl_ r2, chr01
	strb r0, [r2, r1]
	cmp r1, #6
	bcc setbank_ppu
	b mmc3SetBankCpu

@------------------------------------
mmc3MirrorW:		@ A000-BFFF
@------------------------------------
	tst addy, #1
	bne wa001

	strb_ r0, reg2
	ldrb_ r1, cartFlags
	tst r1, #SCREEN4
	bxne lr
	tst r0, #1
	b mirror2V_

wa001:				@ WRAM enable
	strb_ r0, reg3
	bx lr

@------------------------------------
mmc3CounterW:		@ C000-DFFF
@------------------------------------
	tst addy, #1

	streqb_ r0, irq_latch
	bxeq lr

	mov r0, #1
	strb_ r0, irq_reload
	bx lr

@------------------------------------
mmc3IrqEnableW:		@ E000-FFFF
@------------------------------------
	ands r0, addy, #1
	strb_ r0, irq_enable
	beq rp2A03SetIRQPin
	bx lr

@-------------------------------------------------------------------
mmc3HSync:			@ Sharp version, IRQ as long as counter is 0
@-------------------------------------------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuCtrl1
	cmp r0, #240
	bxcs lr
	tst r1, #0x18
	bxeq lr

	ldrb_ r0, irq_reload
	mov r1,#0
	strb_ r1, irq_reload
	ldrb_ r2, irq_counter
	cmp r2,#0				;@ Is counter 0?
	cmpne r0,#1				;@ Or forced reload?
	ldreqb_ r2, irq_latch	;@ Load latch to counter
	subne r2, r2, #1
	strb_ r2, irq_counter
	cmp r2,#0				;@ Is counter 0?
	bxne lr

	ldrb_ r0, irq_enable
	cmp r0,#0
	bxeq lr
	b rp2A03SetIRQPin
@-------------------------------------------------------------------
mmc3HSyncAlt:		@ NEC version, IRQ only on counter n->0 transition
@-------------------------------------------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuCtrl1
	cmp r0, #240
	bxcs lr
	tst r1, #0x18
	bxeq lr

	ldrb_ r0, irq_reload
	mov r1,#0
	strb_ r1, irq_reload
	ldrb_ r2, irq_counter
	movs r1,r2				;@ Keep old counter in r1. Is counter 0?
	cmpne r0,#1				;@ Or forced reload?
	ldreqb_ r2, irq_latch	;@ Load latch to counter
	subne r2, r2, #1
	strb_ r2, irq_counter
	cmp r2,r1				;@ Is old count == new count, no IRQ
	bxeq lr
	cmp r2,#0				;@ Is counter 0?
	bxne lr

	ldrb_ r0, irq_enable
	cmp r0,#0
	bxeq lr
	b rp2A03SetIRQPin
@-------------------------------------------------------------------
hSyncRAMBO1:
@-------------------------------------------------------------------
	ldr_ r0, scanline
	ldrb_ r1, ppuCtrl1

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
	b rp2A03SetIRQPin
@--------
