@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------	
	.global mapper24init
	.global mapper26init
	latch = mapperdata+0
	irqen = mapperdata+1
	k4irq = mapperdata+2
	counter = mapperdata+3
	m26sel = mapperdata+4
@---------------------------------------------------------------------------------
mapper24init:	@Konami VRC6 - Akumajou Densetsu (J)...
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	b Konami_Init
@---------------------------------------------------------------------------------
mapper26init:	@Konami VRC6V - Esper Dream 2, Madara (J)...
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	mov r0,#0x02
	strb_ r0,m26sel
	b Konami_Init
@---------------------------------------------------------------------------------
write8000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	andeqs r2,addy,#3
	beq map89AB_
	@movne pc,lr			@ 0x900x Should really be emulation of the VRC6 soundchip.
	bne soundwrite
@---------------------------------------------------------------------------------
writeA000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	@moveq pc,lr			@ 0xA00x Should really be emulation of the VRC6 soundchip.
	beq soundwrite
	and r1,addy,#0x3
	cmp r1,#0x3				@ 0xB003
	@movne pc,lr			@ !0xB003 Should really be emulation of the VRC6 soundchip.
	bne soundwrite
0:
	mov r0,r0,lsr#2
	b mirrorKonami_
@---------------------------------------------------------------------------------
writeC000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	tsteq addy,#0x3
	beq mapCD_
writeD000:	@addy=D/E/Fxxx
writeE000:
	sub r2,addy,#0xD000
	and addy,addy,#3
	ldrb_ r1,m26sel
	tst r1,#2
	and r1,r1,addy,lsl#1
	orrne addy,r1,addy,lsr#1
	orr r2,addy,r2,lsr#10

	tst r2,#0x08
	ldreq r1,=writeCHRTBL
	adrne r1,writeTable-8*4
	ldr pc,[r1,r2,lsl#2]

writeTable: .word KoLatch,KoCounter,KoIRQen,void
@---------------------------------------------------------------------------------
