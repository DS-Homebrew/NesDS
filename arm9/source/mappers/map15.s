@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper15init
	waste	= mapperdata @8 bytes
@---------------------------------------------------------------------------------
mapper15init:	@100-in-1 Contra 16
@---------------------------------------------------------------------------------
	.word write800x,void,void,void

	mov r0,#0
	b map89ABCDEF_
@---------------------------------------------------------------------------------
write800x:
@---------------------------------------------------------------------------------
	bic addy,addy,#0x8000
	cmp addy,#3
	movhi pc,lr
	bne w80
w83:
	str_ r0,waste
	mov addy,lr
	tst r0,#0x40
	bl mirror2V_
	ldr_ r0,waste
	tst r0,#0x80
	beq swap1_16

	mov r0,r0,lsl#1
	str_ r0,waste
	add r0,r0,#1
	bl mapCD_
	mov lr,addy
	ldr_ r0,waste
	b mapEF_
swap1_16:
	mov lr,addy
	b mapCDEF_
w80:
	cmp addy,#0
	bne w81
	mov addy,lr
	str_ r0,waste
	tst r0,#0x40
	bl mirror2V_
	ldr_ r0,waste
	tst r0,#0x80
	beq swap2_16

	mov r0,r0,lsl#1
	str_ r0,waste
	add r0,r0,#1
	bl map89_
	ldr_ r0,waste
	bl mapAB_
	ldr_ r0,waste
	add r0,r0,#2
	bl mapCD_
	mov lr,addy
	ldr_ r0,waste
	add r0,r0,#1
	b mapEF_
swap2_16:
	bl map89AB_
	mov lr,addy
	ldr_ r0,waste
	add r0,r0,#1
	b mapCDEF_
w81:
	cmp addy,#1
	bne w82
	mov addy,lr
	bl map89AB_
	movs r0,#0			@ Does this set the Z flag?
	bl mirror2V_
	mov r0,#-1
	mov lr,addy
	b mapCDEF_
w82:
	cmp addy,#2
	movne pc,lr

	mov addy,lr
	mov r0,r0,lsl#1
	add r0,r0,r0,lsr#8
	str_ r0,waste

	bl map89_
	ldr_ r0,waste
	bl mapAB_
	ldr_ r0,waste
	bl mapCD_
	mov lr,addy
	ldr_ r0,waste
	b mapEF_
@---------------------------------------------------------------------------------
