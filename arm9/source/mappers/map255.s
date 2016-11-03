@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper255init
	tmp = mapperdata
	tmp1 = mapperdata + 4
	tmp2 = mapperdata + 8
@---------------------------------------------------------------------------------
mapper255init:
@---------------------------------------------------------------------------------
	.word w255, w255, w255, w255
	stmfd sp!, {lr}
	mov r0, #0
	bl map89ABCDEF_
	cmp r0, r0
	bl mirror2V_
	ldmfd sp!, {pc}
	
@-----------------
w255:
@-----------------
	and r0, addy, #0xF80
	mov r0, r0, lsr#5
	and r1, addy, #0x3f
	tst addy, #0x4000
	orrne r0, r0, #0x80
	orrne r1, r1, #0x40
	str_ r1, tmp1
	str_ r0, tmp

	tst addy, #0x1000
	ldreq r2, =0x03020100
	beq chprg
	tst addy, #0x40
	ldreq r2, =0x01000100
	ldrne r2, =0x03020302
chprg:
	stmfd sp!, {lr}
	str_ r2, tmp2

	tst addy, #0x2000
	bl mirror2V_

	ldr_ r2, tmp2
	ldr_ r0, tmp
	and r1, r2, #0xf
	mov r2, r2, lsr#8
	str_ r2, tmp2
	add r0, r0, r1
	bl map89_

	ldr_ r2, tmp2
	ldr_ r0, tmp
	and r1, r2, #0xf
	mov r2, r2, lsr#8
	str_ r2, tmp2
	add r0, r0, r1
	bl mapAB_

	ldr_ r2, tmp2
	ldr_ r0, tmp
	and r1, r2, #0xf
	mov r2, r2, lsr#8
	str_ r2, tmp2
	add r0, r0, r1
	bl mapCD_

	ldr_ r2, tmp2
	ldr_ r0, tmp
	add r0, r0, r2
	bl mapEF_

	ldr_ r0, tmp1
	bl chr01234567_
	ldmfd sp!, {pc}