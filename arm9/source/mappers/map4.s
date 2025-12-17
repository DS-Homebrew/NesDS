;@----------------------------------------------------------------------------
	#include "mmc3.i"
#define	MMC3_IRQ_KLAX		1
#define	MMC3_IRQ_SHOUGIMEIKAN	2
#define	MMC3_IRQ_DAI2JISUPER	3
#define	MMC3_IRQ_DBZ2		4
#define	MMC3_IRQ_ROCKMAN3	5
;@----------------------------------------------------------------------------
	.global mapper4init

	.struct mmc3Extra
vs_patch:	.byte 0
vs_index:	.byte 0
irq_type:	.byte 0

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ MMC3 & MMC6
mapper4init:
;@----------------------------------------------------------------------------
	.word mmc3MappingW, mmc3MirrorW, mmc3CounterW, mmc3IrqEnableW

	adr r0, writel
	str_ r0, rp2A03MemWrite
	adr r0, readl
	str_ r0, rp2A03MemRead

	b mmc3Init

@patch for games...
	@ldrb_ r0, irq_type
	@cmp r0, #MMC3_IRQ_KLAX
	@ldreq r2,=hSyncRAMBO1
	@cmp r0, #MMC3_IRQ_ROCKMAN3
	@ldreq r2,=hSyncRockman3
	@cmp r2, #MMC3_IRQ_DAI2JISUPER
	@ldreq r2,=mmc3HSync___
	@str_ r2,scanlineHook

	@ldr_ r0,prgCrc
	@ldr r1, =0x5807		@Tenchi o Kurau 2 - Akakabe no Tatakai Chinese Edtion.
	@cmp r1, r0
	@ldreq_ r2, emuFlags
	@orreq r2, r2, #PALTIMING
	@streq_ r2, emuFlags

	@bx lr

;@----------------------------------------------------------------------------
writel:		;@ ($4020-$5FFF)
;@----------------------------------------------------------------------------
	cmp addy, #0x5000
	bcc empty_W
	sub r2, addy, #0x4000
	ldr r1, =NES_XRAM
	strb r0, [r1, r2]
	bx lr

;@----------------------------------------------------------------------------
readl:		;@ ($4020-$5FFF)
;@----------------------------------------------------------------------------
	cmp addy, #0x5000
	bcc empty_R
	sub r2, addy, #0x4000
	ldr r1, =NES_XRAM
	ldrb r0, [r1, r2]
	bx lr
