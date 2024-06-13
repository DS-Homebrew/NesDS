@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper73init
	latch = mapperData
	counter = mapperData+4
	irqen = mapperData+8
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Konami VRC3
@ Used in:
@ Salamander (J)
mapper73init:
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
@---------------------------------------------------------------------------------
write8000:
@---------------------------------------------------------------------------------
	ldr_ r2,latch
	and r0,r0,#0xF
	tst addy,#0x1000
	bne write9000
	bic r2,r2,#0x000F0000
	orr r0,r2,r0,lsl#16
	str_ r0,latch
	bx lr
write9000:
	bic r2,r2,#0x00F00000
	orr r0,r2,r0,lsl#20
	str_ r0,latch
	bx lr
@---------------------------------------------------------------------------------
writeA000:
@---------------------------------------------------------------------------------
	ldr_ r2,latch
	and r0,r0,#0xF
	tst addy,#0x1000
	bne writeB000
	bic r2,r2,#0x0F000000
	orr r0,r2,r0,lsl#24
	str_ r0,latch
	bx lr
writeB000:
	bic r2,r2,#0xF0000000
	orr r0,r2,r0,lsl#28
	str_ r0,latch
	bx lr
@---------------------------------------------------------------------------------
writeC000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	bne writeD000
	strb_ r0,irqen
	tst r0,#2				;@ Timer enabled?
	ldrne_ r0,latch
	strne_ r0,counter
	// Ack IRQ
	bx lr
writeD000:
	ldrb_ r0,irqen
	bic r0,r0,#2			;@ Disable Timer.
	orr r0,r0,r0,lsl#1		;@ Move repeat bit to Enable bit
	strb_ r0,irqen
	// Ack IRQ
	bx lr
@---------------------------------------------------------------------------------
writeE000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	bne map89AB_
	bx lr
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r0,irqen
	tst r0,#2				;@ Timer active?
	bxeq lr

	ldr_ r2,counter
	ldr r1,=0x71aaab		;@ 113.66667 (Cycles per scanline)
	tst r0,#4				;@ 8-bit timer?
	bne timer8bit

	adds r2,r2,r1
	bcc h0
	ldr_ r1,latch
	add r2,r2,r1
takeIrq:
	str_ r2,counter
	mov r0,#1
	b rp2A03SetIRQPin
timer8bit:
	mov r2,r2,ror#24
	adds r2,r2,r1,lsl#8
	ldrcs_ r1,latch
	addcs r2,r2,r1,lsl#8
	mov r2,r2,ror#8
	bcs takeIrq
h0:
	str_ r2,counter
	bx lr
@---------------------------------------------------------------------------------
