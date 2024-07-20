;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper246init

;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Used in Taiwanese game
;@ 封神榜 (Fēngshénbǎng: Fúmó Sān Tàizǐ).
mapper246init:
;@----------------------------------------------------------------------------
	.word void, void, void, void
	ldr r0, =writel
	str_ r0, m6502WriteTbl+12

	bx lr
;@----------------------------------------------------------------------------
writel:
	ldr r1, =0x6008
	cmp addy, r1
	bcs sram_W
	and r1, addy, #0x7
	ldr pc,[pc,r1,lsl#2]
	nop
tbl:	.word map89_, mapAB_, mapCD_, mapEF_, chr01_, chr23_, chr45_, chr67_
;@----------------------------------------------------------------------------
