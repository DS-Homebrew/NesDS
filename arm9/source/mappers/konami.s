@---------------------------------------------------------------------------------
.section .text,"ax"
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
latch = mapperdata+0
irqen = mapperdata+1
k4irq = mapperdata+2
counter = mapperdata+3
@---------------------------------------------------------------------------------
Konami_Init:
	ldr r0,=Konami_IRQ_Hook
	str_ r0,scanlinehook
	mov pc,lr
@---------------------------------------------------------------------------------
KoLatch: @- - - - - - - - - - - - - - -
	strb_ r0,latch
	mov pc,lr
KoLatchLo: @- - - - - - - - - - - - - - -
	and r2,r2,#0xf0
	and r0,r0,#0x0f
	orr r0,r0,r2
	strb_ r0,latch
	mov pc,lr
KoLatchHi: @- - - - - - - - - - - - - - -
	and r2,r2,#0x0f
	orr r0,r2,r0,lsl#4
	strb_ r0,latch
	mov pc,lr
KoCounter: @- - - - - - - - - - - - - - -
	ands r1,r0,#2
	and r0,r0,#1
	strb_ r0,k4irq
	strb_ r1,irqen
	ldrneb_ r0,latch
	strneb_ r0,counter
	mov pc,lr
KoIRQen: @- - - - - - - - - - - - - - -
	ldrb_ r0,k4irq
	orr r0,r0,r0,lsl#1
	strb_ r0,irqen
	mov pc,lr
@---------------------------------------------------------------------------------
Konami_IRQ_Hook:
@---------------------------------------------------------------------------------
	ldr_ r0,latch
	tst r0,#0x200	@timer active?
	beq h1

	adds r0,r0,#0x01000000	@counter++
	bcc h0

	strb_ r0,counter	@copy latch to counter
@	b irq6502
	b CheckI
h0:
	str_ r0,latch
h1:
	fetch 0
@---------------------------------------------------------------------------------
