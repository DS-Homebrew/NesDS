@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper159init

 counter = mapperdata+0
 latch = mapperdata+4
 enable = mapperdata+8
@----------------------------------------------------------------------------
mapper159init:@		Bandai
@----------------------------------------------------------------------------
	.word write0,write0,write0,write0

	ldrb_ r1,cartflags		@get cartflags
	bic r1,r1,#SRAM			@don't use SRAM on this mapper
	strb_ r1,cartflags		@set cartflags
	ldr r1,mapper159init
	str_ r1,writemem_tbl+12

	ldr r0,=hook
	str_ r0,scanlinehook

	mov pc,lr
@-------------------------------------------------------
write0:
@-------------------------------------------------------
	and addy,addy,#0x0f
	tst addy,#0x08
	ldreq r1,=writeCHRTBL
	adrne r1,tbl-8*4
	ldr pc,[r1,addy,lsl#2]
wA: @---------------------------
	and r0,r0,#1
	strb_ r0,enable
	ldr_ r0,latch
	str_ r0,counter
	mov pc,lr
wB: @---------------------------
	strb_ r0,latch
asdf:	mov r1,#0
	strb_ r1,latch+2
	strb_ r1,latch+3
	mov pc,lr
wC: @---------------------------
	strb_ r0,latch+1
	b asdf

tbl: .word map89AB_,mirrorKonami_,wA,wB,wC,void,void,void
@-------------------------------------------------------
hook:
@------------------------------------------------------
	ldrb_ r0,enable
	cmp r0,#0
	beq h1

	ldr_ r0,counter
	subs r0,r0,#113
	str_ r0,counter
@	bcc irq6502
	bcc CheckI
h1:
	fetch 0
@-------------------------------------------------------
	@.end
