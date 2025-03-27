;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper18init

	.struct mapperData
prgXX:		.word 0
chrXX:		.word 0, 0
latch: 		.word 0
counter:	.word 0
irqEn:		.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Jaleco SS8806
;@ Used in:
;@ The Lord of King
;@ Magic John
;@ Pizza Pop
mapper18init:
;@----------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
;@----------------------------------------------------------------------------
write8000:
;@----------------------------------------------------------------------------
writeA000:
;@----------------------------------------------------------------------------
writeC000:	@addy=A/B/C/Dxxx
;@----------------------------------------------------------------------------
	and r1,addy,#3
	and addy,addy,#0x7000
	orr r1,r1,addy,lsr#10
	movs r1,r1,lsr#1

	adrl_ addy,prgXX
	and r0,r0,#0xF
	ldrb r2,[addy,r1]

	andcc r2,r2,#0xF0
	orrcc r0,r2,r0
	andcs r2,r2,#0xF
	orrcs r0,r2,r0,lsl#4
	strb r0,[addy,r1]

	cmp r1,#4
	ldrge addy,=writeCHRTBL-4*4
	adrlo addy,write8tbl
	ldr pc,[addy,r1,lsl#2]


write8tbl: .word map89_,mapAB_,mapCD_,void
;@----------------------------------------------------------------------------
writeE000:
;@----------------------------------------------------------------------------
	and r1,addy,#3
	tst addy,#0x1000
	orrne r1,r1,#4

	and r0,r0,#0xF
	ldr_ r2,latch
	ldr pc,[pc,r1,lsl#2]
	nop
writeFtbl: .word wE0,wE1,wE2,wE3,wF0,wF1,wF2,void

wE0: @- - - - - - - - - - - - - - -
	bic r2,r2,#0xF
	orr r0,r2,r0
	str_ r0,latch
	bx lr
wE1: @- - - - - - - - - - - - - - -
	bic r2,r2,#0xF0
	orr r0,r2,r0,lsl#4
	str_ r0,latch
	bx lr
wE2: @- - - - - - - - - - - - - - -
	bic r2,r2,#0xF00
	orr r0,r2,r0,lsl#8
	str_ r0,latch
	bx lr
wE3: @- - - - - - - - - - - - - - -
	bic r2,r2,#0xF000
	orr r0,r2,r0,lsl#12
	str_ r0,latch
	bx lr
wF0: @- - - - - - - - - - - - - - -
	str_ r2,counter
	mov r0,#0
	b rp2A03SetIRQPin
wF1: @- - - - - - - - - - - - - - -
	strb_ r0,irqEn
	mov r0,#0
	b rp2A03SetIRQPin
wF2: @- - - - - - - - - - - - - - -
	movs r1,r0,lsr#2
	tst r0,#1
	bcc mirror2H_
	bcs mirror1_

;@----------------------------------------------------------------------------
hook:
;@----------------------------------------------------------------------------
	ldrb_ r0,irqEn
	tst r0,#1			;@ Timer active?
	bxeq lr

	ldr_ r0,counter
	cmp r0,#0			;@ Timer active?
	bxeq lr
	subs r0,r0,#113		;@ counter-A
	bhi h0

	mov r0,#0
	str_ r0,counter		;@ Clear counter and IRQenable.
	strb_ r0,irqEn
	mov r0,#1
	b rp2A03SetIRQPin
h0:
	str_ r0,counter
	bx lr
;@----------------------------------------------------------------------------
