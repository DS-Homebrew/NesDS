@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper17init
	counter = mapperData+0
	enable = mapperData+4
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mapper17init:
@---------------------------------------------------------------------------------
	.word void,void,void,void

	adr r1,write0
	str_ r1,m6502WriteTbl+8

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
@---------------------------------------------------------------------------------
write0:
@---------------------------------------------------------------------------------
	cmp addy,#0x4100
	blo IO_W

	and r2,addy,#0xff
	cmp r2,#0xfe
	beq _fe
	cmp r2,#0xff
	beq _ff

	and r2,r2,#0x17
	tst r2,#0x10
	subne r2,r2,#8

	adr r1,jmptbl
	ldr pc,[r1,r2,lsl#2]

jmptbl: .word void,_1,_2,_3,map89_,mapAB_,mapCD_,mapEF_
	.word chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_

_fe:
	tst r0,#0x10
	b mirror1_
_ff:
	tst r0,#0x10
	b mirror2V_
_1:
	and r0,r0,#1
	strb_ r0,enable
	bx lr
_2:
	strb_ r0,counter+2
	bx lr
_3:
	strb_ r0,counter+3
	mov r1,#1
	strb_ r1,enable
	bx lr
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r0,enable
	cmp r0,#0
	beq h1

	ldr_ r0,counter
	adds r0,r0,#0x10000
	str_ r0,counter
@	bcs irq6502
	bcs CheckI
h1:
	fetch 0
@---------------------------------------------------------------------------------
