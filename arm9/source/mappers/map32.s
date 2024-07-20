;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper32init

	.struct mapperData
pSwitch:	.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Irem G-101
;@ Used in:
;@ Image Fight (J)
;@ Major League
;@ Kaiketsu Yanchamaru 2
mapper32init:
;@----------------------------------------------------------------------------
	.word write8000,writeA000,void,void

	bx lr
;@----------------------------------------------------------------------------
write8000:
;@----------------------------------------------------------------------------
	tst addy,#0x1000
	bne write9000
	ldrb_ r1,pSwitch
	tst r1,#0x02
	beq map89_
	bne mapCD_
write9000:
	strb_ r0,pSwitch
	tst r0,#0x1
	b mirror2V_
;@----------------------------------------------------------------------------
writeA000:
;@----------------------------------------------------------------------------
	tst addy,#0x1000
	beq mapAB_
	and addy,addy,#7
	ldr r1,=writeCHRTBL
	ldr pc,[r1,addy,lsl#2]
;@----------------------------------------------------------------------------
