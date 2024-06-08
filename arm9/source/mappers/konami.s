@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global Konami_Init
	.global Konami_IRQ_Hook
	.global KoLatch
	.global KoLatchLo
	.global KoLatchHi
	.global KoCounter
	.global KoIRQen
latch = mapperData+0
irqen = mapperData+1
k4irq = mapperData+2
counter = mapperData+3
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
Konami_Init:
	adr r0,Konami_IRQ_Hook
	str_ r0,scanlineHook
	bx lr
@---------------------------------------------------------------------------------
KoLatch: @- - - - - - - - - - - - - - -
	strb_ r0,latch
	bx lr
KoLatchLo: @- - - - - - - - - - - - - - -
	and r2,r2,#0xf0
	and r0,r0,#0x0f
	orr r0,r0,r2
	strb_ r0,latch
	bx lr
KoLatchHi: @- - - - - - - - - - - - - - -
	and r2,r2,#0x0f
	orr r0,r2,r0,lsl#4
	strb_ r0,latch
	bx lr
KoCounter: @- - - - - - - - - - - - - - -
	ands r1,r0,#2
	and r0,r0,#1
	strb_ r0,k4irq
	strb_ r1,irqen
	ldrneb_ r0,latch
	strneb_ r0,counter
	bx lr
KoIRQen: @- - - - - - - - - - - - - - -
	ldrb_ r0,k4irq
	orr r0,r0,r0,lsl#1
	strb_ r0,irqen
	bx lr
@---------------------------------------------------------------------------------
Konami_IRQ_Hook:
@---------------------------------------------------------------------------------
	ldr_ r0,latch
	tst r0,#0x200		;@ Timer active?
	beq h1

	adds r0,r0,#0x01000000	;@ Counter++
	bcc h0

	strb_ r0,counter	;@ Copy latch to counter
@	b irq6502
	b CheckI
h0:
	str_ r0,latch
h1:
	fetch 0
@---------------------------------------------------------------------------------
