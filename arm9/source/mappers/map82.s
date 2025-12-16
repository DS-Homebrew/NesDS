;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper82init
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Taito X1-017 mapper IC
;@ Known games:
;@ SD Keiji: Blader (ＳＤ刑事ブレイダー)
;@ Kyuukyoku Harikiri Stadium 1989 Edition (究極ハリキリスタジアム平成元年版)
;@ Kyuukyoku Harikiri Stadium III (究極ハリキリスタジアムIII)
;@ Kyuukyoku Harikiri Koushien (究極ハリキリ甲子園)
;@ See also mapper 80
;@----------------------------------------------------------------------------
mapper82init:
;@----------------------------------------------------------------------------
	.word rom_W,rom_W,rom_W,rom_W

	adr r1,write0
	str_ r1,m6502WriteTbl+12
	bx lr
;@----------------------------------------------------------------------------
write0:		;@ $6000-7FFF
;@----------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	cmp r1,addy,lsr#4
	bne handleRAM

	and addy,addy,#0xF
	ldr pc,[pc,addy,lsl#2]
	nop
write80tbl: .word wF0,wF1,chr4_,chr5_,chr6_,chr7_,wF6,wF7,wF8,wF9,map89_,mapAB_,mapCD_,irqLatch,irqCtrl,irqReload

handleRAM:
	bxhi lr
	@ Write RAM
	bx lr

wF0:
	mov r0,r0,lsr#1
	b chr01_
wF1:
	mov r0,r0,lsr#1
	b chr23_
wF6:
	ands r0,r0,#1
	b mirror2H_

wF7:	@ Write $CA to enable RAM from $6000 to $67FF, write anything else to disable
wF8:	@ Write $69 to enable RAM from $6800 to $6FFF, write anything else to disable
wF9:	@ Write $84 to enable RAM from $7000 to $73FF, write anything else to disable
irqLatch:
irqCtrl:
irqReload:
	bx lr
;@----------------------------------------------------------------------------
