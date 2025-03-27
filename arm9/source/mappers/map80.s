;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper80init

	.struct mapperData
patch:	.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Taito X1-005 mapper IC
;@ Used in:
;@ Kyonshiizu 2
;@ Minelvaton Saga
;@ Taito Grand Prix - Eikou heno License
;@ See also mapper 82, 207
mapper80init:
;@----------------------------------------------------------------------------
	.word void,void,void,void

	adr r0,write80
	str_ r0,m6502WriteTbl+12
	ldr_ r0,romMask
	tst r0,#0x20000
	movne r0,#1
	moveq r0,#0
	str_ r0,patch

	bx lr
;@----------------------------------------------------------------------------
write80:
;@----------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	cmp r1,addy,lsr#4
	bne handleRAM

	and addy,addy,#0xF
	ldr pc,[pc,addy,lsl#2]
	nop
write80tbl: .word wF0,wF1,chr4_,chr5_,chr6_,chr7_,wF6,wF6,wF8,wF8,map89_,map89_,mapAB_,mapAB_,mapCD_,mapCD_

wF0:
	stmfd sp!,{r0,lr}
	mov r0,r0,lsr#1
	bl chr01_
	ldmfd sp!,{r0,lr}
	ldr_ r1,patch
	cmp r1,#0
	bxeq lr
	tst r0,#0x80
	b mirror1_
wF1:
	mov r0,r0,lsr#1
	b chr23_
wF6:
	ands r0,r0,#1
	b mirror2H_
wF8:
	;@ IRAM permission ($A3 enables reads/writes; any other value disables)
	bx lr

handleRAM:
	bxlo lr
	@ Write RAM
	bx lr

;@----------------------------------------------------------------------------
