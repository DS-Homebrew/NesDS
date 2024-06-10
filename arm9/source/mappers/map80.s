@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper80init
	patch = mapperData+0
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Taito X1-005 mapper IC
@ See also mapper 82
mapper80init:
@---------------------------------------------------------------------------------
	.word void,void,void,void

	ldrb_ r1,cartFlags
	bic r1,r1,#SRAM			@don't use SRAM on this mapper
	strb_ r1,cartFlags

	adr r0,write80
	str_ r0,m6502WriteTbl+12
	ldr_ r0,romMask
	tst r0,#0x20000
	movne r0,#1
	moveq r0,#0
	str_ r0,patch

	bx lr
@---------------------------------------------------------------------------------
write80:
@---------------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	teq r1,addy,lsr#4
	bxne lr

	and addy,addy,#0xF
	ldr pc,[pc,addy,lsl#2]
	nop
write80tbl: .word wF0,wF1,chr4_,chr5_,chr6_,chr7_,wF6,void,void,void,map89_,map89_,mapAB_,mapAB_,mapCD_,mapCD_

wF0:
	mov addy,r0
	stmfd sp!,{r0,lr}
	bl chr0_
	ldr_ r1,patch
	cmp r1,#0
	beq noPatch
	tst addy,#0x80
	bl mirror1_
noPatch:
	ldmfd sp!,{r0,lr}
	add r0,r0,#1
	b chr1_
wF1:
	stmfd sp!,{r0,lr}
	bl chr2_
	ldmfd sp!,{r0,lr}
	add r0,r0,#1
	b chr3_
wF6:
	ands r0,r0,#1
	b mirror2H_


@---------------------------------------------------------------------------------
