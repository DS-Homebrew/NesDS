@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper65init
	latch = mapperData+0
	counter = mapperData+4
	irqen = mapperData+8
	mswitch = mapperData+9
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Irem H3001
@ Used in:
@ Daiku no Gen San 2
@ Kaiketsu Yanchamaru 3
@ Spartan X 2
mapper65init:
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
	ldr pc,[pc,addy,lsl#2]
	nop
write9tbl: .word w90,w91,void,w93,w94,w95,w96,void

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
	mov r0,#0
	b rp2A03SetIRQPin
w94:
	ldr_ r2,latch
	str_ r2,counter
	mov r0,#0
	b rp2A03SetIRQPin
w95:
	strb_ r0,latch+1
	bx lr
w96:
	strb_ r0,latch
	bx lr

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
	bxeq lr

	ldr_ r0,counter
	subs r0,r0,#113		@counter-A
	bhi h0

	mov r0,#0
	strb_ r0,irqen
	str_ r0,counter		@ clear counter and IRQenable.
	mov r0,#1
	b rp2A03SetIRQPin
h0:
	str_ r0,counter
	bx lr
@---------------------------------------------------------------------------------
