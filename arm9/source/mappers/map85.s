@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------	
	.global mapper85init
	latch = mapperData+0
	irqen = mapperData+1
	k4irq = mapperData+2
	counter = mapperData+3
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
mapper85init:	@2Konami - Tiny Toon Adventure 2 (J)...
		@ Lagrange Point, requires CHRRAM swappability  =)
@---------------------------------------------------------------------------------
	.word write85,write85,write85,write85
	b Konami_Init
VRC7:
	bx lr
@---------------------------------------------------------------------------------
write85:
@---------------------------------------------------------------------------------
	mov r1,addy,lsr#11
	and r1,r1,#0xE
	tst addy,#0x8
	orrne r1,r1,#1
	tst addy,#0x10
	orrne r1,r1,#1

	adr addy,tbl85
	ldr pc,[addy,r1,lsl#2]

tbl85:	.word map89_,mapAB_,mapCD_,VRC7,chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_,mirrorKonami_,KoLatch,KoCounter,KoIRQen
@---------------------------------------------------------------------------------
