;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper82init

	.struct mapperData
charMode:		.byte 0
ram60Enable:	.byte 0
ram68Enable:	.byte 0
ram70Enable:	.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Taito X1-017 mapper IC
;@ Known games:
;@ SD Keiji: Blader (ＳＤ刑事ブレイダー)
;@ Kyuukyoku Harikiri Stadium 1989 Edition (究極ハリキリスタジアム平成元年版)
;@ Kyuukyoku Harikiri Stadium III (究極ハリキリスタジアムIII)
;@ Kyuukyoku Harikiri Koushien (究極ハリキリ甲子園)
;@ See also mapper 552
;@----------------------------------------------------------------------------
mapper82init:
;@----------------------------------------------------------------------------
	.word rom_W,rom_W,rom_W,rom_W

	adr r1,readRAM
	str_ r1,m6502ReadTbl+12
	adr r1,write0
	str_ r1,m6502WriteTbl+12
	bx lr
;@----------------------------------------------------------------------------
write0:		;@ $6000-7FFF
;@----------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	cmp r1,addy,lsr#4
	bne writeRAM

	and addy,addy,#0xF
	ldr pc,[pc,addy,lsl#2]
	nop
write82tbl:
	.word wF0,wF1,wF2,wF3,wF4,wF5,wF6,wF7,wF8,wF9,wFA,wFB,wFC,irqLatch,irqCtrl,irqReload

writeRAM:
	cmp addy,#0x7400
	bcs empty_W
	and r1,addy,#0x1800
	cmp r1,#0x0800
	ldrccb_ r1,ram60Enable
	subcc r1,r1,#0xCA
	ldreqb_ r1,ram68Enable
	subeq r1,r1,#0x69
	ldrhib_ r1,ram70Enable
	subhi r1,r1,#0x84
	cmp r1,#0
	bne empty_W
	b sram_W
readRAM:
	cmp addy,#0x7400
	bcs empty_R
	and r1,addy,#0x1800
	cmp r1,#0x0800
	ldrccb_ r1,ram60Enable
	subcc r1,r1,#0xCA
	ldreqb_ r1,ram68Enable
	subeq r1,r1,#0x69
	ldrhib_ r1,ram70Enable
	subhi r1,r1,#0x84
	cmp r1,#0
	bne empty_R
	b mem_R60

wF0:
	mov r0,r0,lsr#1
	ldrb_ r1,charMode
	tst r1,#2
	beq chr01_
	b chr45_
wF1:
	mov r0,r0,lsr#1
	ldrb_ r1,charMode
	tst r1,#2
	beq chr23_
	b chr67_
wF2:
	ldrb_ r1,charMode
	tst r1,#2
	beq chr4_
	b chr0_
wF3:
	ldrb_ r1,charMode
	tst r1,#2
	beq chr5_
	b chr1_
wF4:
	ldrb_ r1,charMode
	tst r1,#2
	beq chr6_
	b chr2_
wF5:
	ldrb_ r1,charMode
	tst r1,#2
	beq chr7_
	b chr3_
wF6:
	strb_ r0,charMode
	ands r0,r0,#1
	b mirror2H_

wF7:	@ Write $CA to enable RAM from $6000 to $67FF, write anything else to disable
	strb_ r0,ram60Enable
	bx lr
wF8:	@ Write $69 to enable RAM from $6800 to $6FFF, write anything else to disable
	strb_ r0,ram68Enable
	bx lr
wF9:	@ Write $84 to enable RAM from $7000 to $73FF, write anything else to disable
	strb_ r0,ram70Enable
	bx lr
wFA:
	mov r0,r0,lsr#2
	b map89_
wFB:
	mov r0,r0,lsr#2
	b mapAB_
wFC:
	mov r0,r0,lsr#2
	b mapCD_

irqLatch:
irqCtrl:
irqReload:
	bx lr
;@----------------------------------------------------------------------------
