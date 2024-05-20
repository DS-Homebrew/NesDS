@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper65init
	latch = mapperData+0
	counter = mapperData+4
	irqen = mapperData+8
	mswitch = mapperData+9
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mapper65init:	@Irem, Spartan X 2...
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,void

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
@---------------------------------------------------------------------------------
write8000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	beq map89_

write9000:
	and addy,addy,#7
	adr r1,write9tbl
	ldr pc,[r1,addy,lsl#2]

w90:
	ldrb_ r1,mswitch
	cmp r1,#0
	bxne lr
	tst r0,#0x40
	b mirror2H_
w91:
	mov r1,#1
	strb_ r1,mswitch
	tst r0,#0x80
	b mirror2V_
w93:
	and r0,r0,#0x80
	strb_ r0,irqen
	bx lr
w94:
	ldr_ r2,latch
	str_ r2,counter
	bx lr
w95:
	strb_ r0,latch+1
	bx lr
w96:
	strb_ r0,latch
	bx lr

write9tbl: .word w90,w91,void,w93,w94,w95,w96,void
@---------------------------------------------------------------------------------
writeA000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	beq mapAB_
writeB000:
	and addy,addy,#7
	ldr r1,=writeCHRTBL
	ldr pc,[r1,addy,lsl#2]
@---------------------------------------------------------------------------------
writeC000:
@---------------------------------------------------------------------------------
	cmp addy,#0xC000
	beq mapCD_
	bx lr
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r0,irqen
	cmp r0,#0	@timer active?
	beq h1

	ldr_ r0,counter
	subs r0,r0,#113		@counter-A
	bhi h0

	mov r0,#0
	strb_ r0,irqen
	str_ r0,counter	@clear counter and IRQenable.
@	b irq6502
	b CheckI
h0:
	str_ r0,counter
h1:
	fetch 0
@---------------------------------------------------------------------------------
