@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper23init
	latch = mapperData+0
	irqen = mapperData+1
	k4irq = mapperData+2
	counter = mapperData+3
	k4sel = mapperData+4
	chr_xx = mapperData+6 @16 bytes
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Konami VRC2b & VRC4e
@ Boku Dracula-kun
@ Tiny Toon Adventures (J)
@ Wai Wai World
@ Also see mapper 21, 22 & 25
mapper23init:
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	b Konami_Init
@---------------------------------------------------------------------------------
write8000:
@---------------------------------------------------------------------------------
	cmp addy,#0x9000
	bge write9000
	ldrb_ r1,k4sel
	ands r1,r1,#2
	beq map89_
	bne mapCD_

write9000:
	orr addy,addy,addy,lsr#4		@0x55=1, 0xAA=2
	orr addy,addy,addy,lsr#2
	ands addy,addy,#3
	beq mirrorKonami_
w90_:
	strb_ r0,k4sel
	bx lr
@---------------------------------------------------------------------------------
writeA000:
@---------------------------------------------------------------------------------
	cmp addy,#0xb000
	bmi mapAB_
writeC000:	@addy=B/C/D/Exxx
@---------------------------------------------------------------------------------
	and r0,r0,#0x0f

	sub r2,addy,#0xB000
	and r2,r2,#0x3000
	tst addy,#0x55
	orrne r2,r2,#0x400
	tst addy,#0xAA
	orrne r2,r2,#0x800

	adrl_ r1,chr_xx

	strb r0,[r1,r2,lsr#10]
	bic r2,r2,#0x400
	ldrb r0,[r1,r2,lsr#10]!			@ writeback address
	ldrb r1,[r1,#1]
	orr r0,r0,r1,lsl#4

	ldr r1,=writeCHRTBL
	ldr pc,[r1,r2,lsr#9]
@---------------------------------------------------------------------------------
writeE000:
@---------------------------------------------------------------------------------
	cmp addy,#0xf000
	bmi writeC000

	orr addy,addy,addy,lsr#4		@0x55=1, 0xAA=2
	orr addy,addy,addy,lsr#2
	and addy,addy,#3
	ldr pc,[pc,addy,lsl#2]
	nop
writeFtbl: .word KoLatchLo,KoLatchHi,KoIRQEnable,KoIRQack
@---------------------------------------------------------------------------------
