@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper33init
	.global mapper48init
	latch = mapperData+0
	irqen = mapperData+1
	counter = mapperData+3
	mswitch = mapperData+4
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Taito TC0190
@ Used in:
@ Akira
@ Bakushou!! Jinsei Gekijou
@ Don Doko Don
@ Insector X
mapper33init:
@---------------------------------------------------------------------------------
@ Taito TC0690
@ Used in:
@ Bakushou!! Jinsei Gekijou 3
@ Bubble Bobble 2 (J)
@ Captain Saver (J)
@ Don Doko Don 2
@ Flintstones, The - The Rescue of Dino & Hoppy (J)
@ Jetsons, The - Cogswell's Caper! (J)
mapper48init:
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	adr r0,hook
	str_ r0,scanlineHook

	bx lr
@---------------------------------------------------------------------------------
write8000:
@---------------------------------------------------------------------------------
	and addy,addy,#3
	ldr pc,[pc,addy,lsl#2]
	nop
write8tbl: .word w80,mapAB_,chr01_,chr23_
w80:
	ldr_ r1,mswitch
	tst r1,#0xFF
	bne map89_
	stmfd sp!,{r0,lr}
	tst r0,#0x40
	bl mirror2V_
	ldmfd sp!,{r0,lr}
	b map89_

@---------------------------------------------------------------------------------
writeA000:
@---------------------------------------------------------------------------------
	and addy,addy,#3
	ldr r1,=writeCHRTBL+4*4		@chr4_,chr5_,chr6_,chr7_
	ldr pc,[r1,addy,lsl#2]
@---------------------------------------------------------------------------------
writeC000:						@ Only mapper 48
@---------------------------------------------------------------------------------
	ands addy,addy,#3
	streqb_ r0,latch
	bxeq lr
	cmp addy,#2
	mov r0,addy
	movhi r0,#0
	strplb_ r0,irqen
	bhi rp2A03SetIRQPin
	ldrmib_ r0,latch
	strmib_ r0,counter
	bx lr
@---------------------------------------------------------------------------------
writeE000:						@ Only mapper 48
@---------------------------------------------------------------------------------
	mov r1,#1
	strb_ r1,mswitch
	tst r0,#0x40
	b mirror2V_
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r0,ppuCtrl1
	tst r0,#0x18		@no sprite/BG enable?
	bxeq lr			@bye..

	ldr_ r0,scanline
	cmp r0,#1		@not rendering?
	bxlt lr			@bye..

	ldr_ r0,scanline
	cmp r0,#240		@not rendering?
	bxhi lr			@bye..

	ldr_ r0,latch
	tst r0,#0x200	@irq timer active?
	bxeq lr

	adds r0,r0,#0x01000000	@counter++
	bcc h0

	strb_ r0,counter	@copy latch to counter
	mov r0,#1
	b rp2A03SetIRQPin
h0:
	str_ r0,latch
	bx lr
@---------------------------------------------------------------------------------
