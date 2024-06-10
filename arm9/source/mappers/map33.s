@---------------------------------------------------------------------------------
	#include "equates.h"
	#include "6502mac.h"
@---------------------------------------------------------------------------------
	.global mapper33init
	irqen = mapperData+0
	counter = mapperData+3
	mswitch = mapperData+4
	pswitch = mapperData+5
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
writeC000:
@---------------------------------------------------------------------------------
	ands addy,addy,#3
	bne wC1
	strb_ r0,counter
	bx lr
wC1:
	cmp addy,#1
	streqb_ r0,irqen
	bx lr
@---------------------------------------------------------------------------------
writeE000:
@---------------------------------------------------------------------------------
	ands addy,addy,#3
	bne wC1
	mov r1,#1
	strb_ r1,mswitch
	tst r0,#0x40
	b mirror2V_
@---------------------------------------------------------------------------------
hook:
@---------------------------------------------------------------------------------
	ldrb_ r0,ppuCtrl1
	tst r0,#0x18		@no sprite/BG enable?
	beq h1			@bye..

	ldr_ r0,scanline
	cmp r0,#1		@not rendering?
	blt h1			@bye..

	ldr_ r0,scanline
	cmp r0,#240		@not rendering?
	bhi h1			@bye..

	ldr_ r0,irqen
	tst r0,#0xFF		@irq timer active?
	beq h1

	adds r0,r0,#0x01000000	@counter++
	bcc h0

	mov r0,#0
	str_ r0,irqen	@copy latch to counter
@	b irq6502
	b CheckI
h0:
	str_ r0,irqen
h1:
	fetch 0
@---------------------------------------------------------------------------------
