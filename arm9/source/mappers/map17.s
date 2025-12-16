;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper17init

	.struct mapperData
counter:	.word 0
enable:		.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Front Fareast Super Magic Card
mapper17init:
;@----------------------------------------------------------------------------
	.word rom_W,rom_W,rom_W,rom_W

	adr r1,write0
	str_ r1,rp2A03MemWrite

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
;@----------------------------------------------------------------------------
write0:
;@----------------------------------------------------------------------------
	cmp addy,#0x4100
	blo empty_W

	and r2,addy,#0xff
	cmp r2,#0xfe
	beq _fe
	cmp r2,#0xff
	beq _ff

	and r2,r2,#0x17
	tst r2,#0x10
	subne r2,r2,#8

	ldr pc,[pc,r2,lsl#2]
	nop
jmptbl: .word void,_1,_2,_3,map89_,mapAB_,mapCD_,mapEF_
	.word chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_

_fe:
	tst r0,#0x10
	b mirror1_
_ff:
	tst r0,#0x10
	b mirror2V_
_1:
	mov r0,#0
	strb_ r0,enable
	b rp2A03SetIRQPin
_2:
	strb_ r0,counter+2
	mov r0,#0
	b rp2A03SetIRQPin
_3:
	strb_ r0,counter+3
	mov r1,#1
	strb_ r1,enable
	mov r0,#0
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb_ r0,enable
	cmp r0,#0
	bxeq lr

	ldr_ r0,counter
	adds r0,r0,#0x10000
	str_ r0,counter
	bxcc lr
	mov r0,#1
	b rp2A03SetIRQPin
;@----------------------------------------------------------------------------
