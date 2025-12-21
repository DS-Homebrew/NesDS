;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper80init
	.global mapper207init

	.struct mapperData
ramEnable:	.byte 0
patch:		.byte 0
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ Taito X1-005 mapper IC
;@ Used in:
;@ Kyonshiizu 2
;@ Minelvaton Saga
;@ Taito Grand Prix - Eikou heno License
;@ See also mapper 82
mapper80init:
mapper207init:
;@----------------------------------------------------------------------------
	.word rom_W,rom_W,rom_W,rom_W

	adr r0,read80
	str_ r0,m6502ReadTbl+12
	adr r0,write80
	str_ r0,m6502WriteTbl+12
	ldr_ r0,romMask
	tst r0,#0x20000
	movne r0,#1
	moveq r0,#0
	strb_ r0,patch

	bx lr
;@----------------------------------------------------------------------------
write80:
;@----------------------------------------------------------------------------
	mov r1,#0x7F0
	sub r1,r1,#1
	cmp r1,addy,lsr#4
	bne writeRAM

	and addy,addy,#0xF
	ldr pc,[pc,addy,lsl#2]
	nop
write80tbl:
	.word wF0,wF1,chr4_,chr5_,chr6_,chr7_,wF6,wF6,wF8,wF8,map89_,map89_,mapAB_,mapAB_,mapCD_,mapCD_

wF0:
	stmfd sp!,{r0,lr}
	mov r0,r0,lsr#1
	bl chr01_
	ldmfd sp!,{r0,lr}
	ldrb_ r1,patch
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
	strb_ r0,ramEnable
	bx lr

writeRAM:
	bcs empty_W
	ldrb_ r1,ramEnable
	cmp r1,#0xA3
	bne empty_W
	orr addy,addy,#0x80
	b sram_W
;@----------------------------------------------------------------------------
read80:
;@----------------------------------------------------------------------------
	cmp addy,#0x7F00
	bcc empty_R
	ldrb_ r0,ramEnable
	cmp r0,#0xA3
	bne empty_R
	orr addy,addy,#0x80
	b mem_R60

;@----------------------------------------------------------------------------
