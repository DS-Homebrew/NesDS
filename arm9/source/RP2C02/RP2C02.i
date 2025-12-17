
globalptr	.req r10		;@ =wram_globals* ptr
addy		.req r12		;@ Keep this at r12 (scratch for APCS)

NDS_PALETTE		= 0x5000000

/** Revision of chip */
	.equ REV_RP2C02,	0x00	;@ NTSC first revision(s)
	.equ REV_RP2C03,	0x01	;@ NTSC RGB revision
	.equ REV_RP2C04,	0x02	;@ NTSC RGB revision
	.equ REV_RP2C05,	0x03	;@ NTSC RGB revision
	.equ REV_RP2C07,	0x10	;@ PAL revision
	.equ REV_UA6528P, 	0x23	;@ UMC UA6528P, Argentina Famiclone
	.equ REV_UA6538, 	0x24	;@ UMC UA6538, aka Dendy
	.equ REV_UA6548, 	0x25	;@ UMC UA6548, Brazil Famiclone

						;@ RP2C02.s
	rp2c02ptr	.req m6502ptr
	.struct rp2A03Size
rp2C02Start:
scanline:		.long 0			;@ These 3 must be first in state.
nextLineChange:	.long 0
lineState:		.long 0
frame:			.long 0
cyclesPerScanline:	 .long 0
lastScanline:	.long 0

ppuState:
vramAddr:		.long 0
vramAddr2:		.long 0
scrollX:		.long 0
scrollY:		.long 0
scrollYTemp:	.long 0
sprite0Y:		.long 0
bg0Cnt:			.long 0
ppuBusLatch:	.byte 0
sprite0X:		.byte 0
vramAddrInc:	.byte 0
toggle:			.byte 0

ppuCtrl0:		.byte 0			;@ These 4 need to be together
ppuCtrl1:		.byte 0
ppuStat:		.byte 0
ppuOamAdr:		.byte 0

ppuCtrl0Frame:	.byte 0
readTemp:		.byte 0
rp2C02Revision:	.byte 0
unusedAlign:	.skip 1

loopy_t:		.long 0
loopy_x:		.long 0
loopy_y:		.long 0
loopy_v:		.long 0

vmemMask:		.long 0
vmemBase:		.long 0
palSyncLine:	.long 0

pixStart:		.long 0
pixEnd:			.long 0
unused:			.long 0

nesChrMap:		.space 8*2
ppuOAMMem:		.space 64*4
paletteMem:		.space 32	;@ NES $3F00-$3F1F

ppuIrqFunc:		.long 0
newFrameHook:	.long 0
endFrameHook:	.long 0
scanlineHook:	.long 0
ppuChrLatch:	.long 0
unusedAlign2:	.skip 8
rp2C02End:

rp2C02Size = rp2C02End-rp2C02Start

;@----------------------------------------------------------------------------
