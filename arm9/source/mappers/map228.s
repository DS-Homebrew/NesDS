@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------	
	.global mapper228init
	mapbyte1 = mapperdata
@---------------------------------------------------------------------------------
mapper228init:@		Action 52 & Cheetahmen 2. PocketNES only support 256k of CHR, Action52 got 512k.
@---------------------------------------------------------------------------------
	.word write0,write0,write0,write0

	stmfd sp!, {lr}
	mov r0, #0
	bl chr01234567_

	mov r0,#0
	bl map89ABCDEF_
	ldmfd sp!, {pc}
@---------------------------------------------------------------------------------
write0:
@---------------------------------------------------------------------------------
	str_ addy,mapbyte1
	and r0,r0,#0x03
	orr r0,r0,addy,lsl#2
	and r0,r0,#0x3F
	mov addy,lr				@we should not change the addy value....

	bl chr01234567_

	ldr_ r0,mapbyte1
	tst r0,#0x2000
	bl mirror2V_

	ldr_ r0,mapbyte1
	tst r0,#0x1000
	bicne r0,r0,#0x800
	
	tst r0,#0x20
	bne swap16k
	mov r0,r0,lsr#7
	and r0,r0,#0x3f
	mov lr,addy
	b map89ABCDEF_

swap16k:
	mov r1,r0,lsr#6
	tst r0,#0x40
	orrne r1,r1,#1
	biceq r1,r1,#1
	mov r0,r1,lsl#1
	str_ r0,mapbyte1
	bl mapCDEF_
	ldr_ r0,mapbyte1
	mov lr,addy
	b map89AB_
@---------------------------------------------------------------------------------
