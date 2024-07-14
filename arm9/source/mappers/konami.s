@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global Konami_Init
	.global Konami_IRQ_Hook
	.global KoLatch
	.global KoLatchLo
	.global KoLatchHi
	.global KoIRQEnable
	.global KoIRQack

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
	ldrb_ r1,latch
	and r1,r1,#0xf0
	and r0,r0,#0x0f
	orr r0,r1,r0
	strb_ r0,latch
	bx lr
KoLatchHi: @- - - - - - - - - - - - - - -
	ldrb_ r1,latch
	and r1,r1,#0x0f
	orr r0,r1,r0,lsl#4
	strb_ r0,latch
	bx lr
KoIRQEnable: @- - - - - - - - - - - - - - -
	strb_ r0,irqen
	tst r0,#2			;@ Timer Enable
	ldrneb_ r0,latch
	strneb_ r0,counter
	mov r0, #0
	b rp2A03SetIRQPin
KoIRQack: @- - - - - - - - - - - - - - -
	ldrb_ r0,irqen
	bic r0,r0,#2		;@ Disable Timer
	orr r0,r0,r0,lsl#1	;@ Move repeat bit to Enable bit
	strb_ r0,irqen
	mov r0, #0
	b rp2A03SetIRQPin
@---------------------------------------------------------------------------------
Konami_IRQ_Hook:
@---------------------------------------------------------------------------------
	ldr_ r0,latch
	tst r0,#0x200		;@ Timer active?
	bxeq lr

	mov r1,#1
	tst r0,#0x400		;@ Cycle Mode?
	movne r1,#114		;@ 114 cpu cycles per scanline
	adds r0,r0,r1,lsl#24	;@ Counter++
	bcc h0

	strb_ r0,counter	;@ Copy latch to counter
	mov r0,#1
	b rp2A03SetIRQPin
h0:
	str_ r0,latch
	bx lr
@---------------------------------------------------------------------------------
