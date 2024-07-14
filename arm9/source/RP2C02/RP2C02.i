
globalptr	.req r10	@ =wram_globals* ptr
addy		.req r12		;@ Keep this at r12 (scratch for APCS)

NDS_PALETTE		= 0x5000000

						;@ RP2C02.s
	rp2c02ptr	.req m6502ptr
	.struct rp2A03Size
rp2C02Start:
scanline:		.long 0			;@ These 3 must be first in state.
nextLineChange:	.long 0
lineState:		.long 0
scanlineHook:	.long 0
frame:			.long 0
cyclesPerScanline:	 .long 0
lastScanline:	.long 0

fpsValue:		.long 0
adjustBlend:	.long 0

ppuState:
vramAddr:		.long 0
vramAddr2:		.long 0
scrollX:		.long 0
scrollY:		.long 0
scrollYTemp:	.long 0
sprite0Y:		.long 0
readTemp:		.long 0
bg0Cnt:			.long 0
ppuBusLatch:	.byte 0
sprite0X:		.byte 0
vramAddrInc:	.byte 0
toggle:			.byte 0
ppuCtrl0:		.byte 0
ppuCtrl1:		.byte 0
ppuStat:		.byte 0
ppuOamAdr:		.byte 0
ppuCtrl0Frame:	.byte 0
unusedAlign:	.skip 3
unusedAlign2:	.skip 8
nesChrMap:		.skip 8*2

loopy_t:		.long 0
loopy_x:		.long 0
loopy_y:		.long 0
loopy_v:		.long 0
loopy_shift:	.long 0

vromMask:		.long 0
vromBase:		.long 0
palSyncLine:	.long 0

pixStart:		.long 0
pixEnd:			.long 0

newFrameHook:	.long 0
endFrameHook:	.long 0
hblankHook:		.long 0
ppuChrLatch:	.long 0
ppuOAMMem:		.skip 64*4

ppuIrqFunc:		.long 0
rp2C02End:

rp2C02Size = rp2C02End-rp2C02Start

;@----------------------------------------------------------------------------
