@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper80init
	patch = mapperdata+0
@---------------------------------------------------------------------------------
mapper80init:	@Taito
@---------------------------------------------------------------------------------
	.word void,void,void,void

	ldrb_ r1,cartflags
	
	bic r1,r1,#SRAM			@don't use SRAM on this mapper
	strb r1,[r0]

	adr r0,write80
	str_ r0,writemem_tbl+12
	ldr_ r0,rommask
	tst r0,#0x20000
	movne r0,#1
	moveq r0,#0
	str_ r0,patch

	mov pc,lr
@---------------------------------------------------------------------------------
write80:
@---------------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	teq r1,addy,lsr#4
	movne pc,lr

	and addy,addy,#0xF
	adr r1,write80tbl
	ldr pc,[r1,addy,lsl#2]

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


write80tbl: .word wF0,wF1,chr4_,chr5_,chr6_,chr7_,wF6,void,void,void,map89_,map89_,mapAB_,mapAB_,mapCD_,mapCD_
@---------------------------------------------------------------------------------

