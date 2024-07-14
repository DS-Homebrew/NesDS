@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper64init
	latch = mapperData+0
	irqen = mapperData+1
	rmode = mapperData+2
	countdown = mapperData+3
	cmd = mapperData+4
	bank0 = mapperData+5
	reload = mapperData+6
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Tengen RAMBO-1
@ Used in:
@ Hard Drivin' (prototype)
@ Klax
@ Rolling Thunder
@ Shinobi
@ Skull and Crossbones
@ Also see mapper 158
mapper64init:
@---------------------------------------------------------------------------------
	.word write0,write1,write2,write3

	adr r0,RAMBO1HSync
	str_ r0,scanlineHook

	bx lr
@---------------------------------------------------------------------------------
write0:		@$8000-8001
@---------------------------------------------------------------------------------
	tst addy,#1
	streqb_ r0,cmd
w8001:
	ldrb_ r1,cmd
	and r1,r1,#0xF
	ldrne pc,[pc,r1,lsl#2]
	bx lr
@---------------------------------------------------------------------------------
commandlist:	.word cmd0,cmd1,chr4_,chr5_,chr6_,chr7_,map89_,mapAB_
				.word cmd0x,cmd1x,void,void,void,void,void,mapCD_
@---------------------------------------------------------------------------------

cmd0:			@0000-07ff
	ldrb_ r1,cmd
	tst r1,#0x20
	bne chr0_
	mov r0,r0,lsr#1
	b chr01_
cmd1:			@0800-0fff
	ldrb_ r1,cmd
	tst r1,#0x20
	bne chr2_
	mov r0,r0,lsr#1
	b chr23_

cmd0x:			@1000-17ff
	ldrb_ r1,cmd
	tst r1,#0x20
	bxeq lr
	mov r0,r0,lsr#1
	b chr1_
cmd1x:			@1800-1fff
	ldrb_ r1,cmd
	tst r1,#0x20
	bxeq lr
	mov r0,r0,lsr#1
	b chr3_
@---------------------------------------------------------------------------------
write1:		@$A000-A001
@---------------------------------------------------------------------------------
	tst addy,#1
	bxne lr
	tst r0,#1
	b mirror2V_
@---------------------------------------------------------------------------------
write2:		@C000-C001
@---------------------------------------------------------------------------------
	ands addy,addy,#1
	streqb_ r0,latch
	strneb_ r0,rmode
	movne r0,#0
	strneb_ r0,countdown
	bx lr
@---------------------------------------------------------------------------------
write3:		@E000-E001
@---------------------------------------------------------------------------------
	ands r0,addy,#1
	strb_ r0,irqen
	beq rp2A03SetIRQPin
	bx lr
@---------------------------------------------------------------------------------
RAMBO1HSync:
@---------------------------------------------------------------------------------
@	ldrb r0,ppuCtrl1
@	tst r0,#0x18	@no sprite/BG enable?  0x18
@	bxeq lr			@bye..

	ldr_ r0,scanline
	cmp r0,#240		@not rendering?
	bxhi lr			@bye..

	ldrb_ r0,countdown
	subs r0,r0,#1
	ldrmib_ r0,latch
	strb_ r0,countdown
	bxne lr

	ldrb_ r0,irqen
	cmp r0,#0
	bne rp2A03SetIRQPin
	bx lr
@---------------------------------------------------------------------------------
