@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper21init
	.global mapper25init
	latch = mapperData+0
	irqen = mapperData+1
	k4irq = mapperData+2
	counter = mapperData+3
	k4sel = mapperData+4
	k4map1 = mapperData+5
	chr_xx = mapperData+8 @16 bytes
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Konami VRC2c & VRC4(a,b,c&d)
@ Used in:
@ Gradius 2
@ Wai Wai World 2
@ Also see mapper 22 & 23
mapper21init:
mapper25init:
@---------------------------------------------------------------------------------
	.word write8000,writeA000,writeC000,writeE000

	b Konami_Init
@---------------------------------------------------------------------------------
write8000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	bne write9000
	strb_ r0,k4map1
	b romswitch

write9000:
	orr addy,addy,addy,lsr#2
	ands addy,addy,#3
	beq mirrorKonami_
	cmp addy,#1
	bxne lr
w91:
	strb_ r0,k4sel
romswitch:
	mov addy,lr
	ldrb_ r0,k4sel
	tst r0,#2
	mov r0,#-2
	bne reverseMap
	bl mapCD_
	mov lr,addy
	ldrb_ r0,k4map1
	b map89_
reverseMap:
	bl map89_
	mov lr,addy
	ldrb_ r0,k4map1
	b mapCD_
@---------------------------------------------------------------------------------
writeA000:
@---------------------------------------------------------------------------------
	tst addy,#0x1000
	beq mapAB_
writeC000:	@addy=B/C/D/Exxx
@---------------------------------------------------------------------------------
	sub r2,addy,#0xB000
	and r2,r2,#0x3000
	tst addy,#0x85			@0x01 + 0x04 + 0x80
	orrne r2,r2,#0x800
	tst addy,#0x4A			@0x02 + 0x08 + 0x40
	orrne r2,r2,#0x4000

	adrl_ r1,chr_xx
	and r0,r0,#0x0f

	strb r0,[r1,r2,lsr#11]
	bic r2,r2,#0x4000
	ldrb r0,[r1,r2,lsr#11]!
	ldrb r1,[r1,#8]
	orr r0,r0,r1,lsl#4

	ldr r1,=writeCHRTBL
	ldr pc,[r1,r2,lsr#9]
@---------------------------------------------------------------------------------
writeE000:
@---------------------------------------------------------------------------------
	cmp addy,#0xf000
	bmi writeC000

	tst addy,#0x85			@0x04 + 0x01 + 0x80
	orrne addy,addy,#0x1
	tst addy,#0x4A			@0x02 + 0x08 + 0x40
	orrne addy,addy,#0x2
	and addy,addy,#3
	ldrb_ r2,latch
	ldr pc,[pc,addy,lsl#2]
	nop
writeFtbl: .word KoLatchLo,KoCounter,KoLatchHi,KoIRQen
@---------------------------------------------------------------------------------
