@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper70init
	.global mapper152init
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Bandai mapper 70, no mirroring
@ Many of these games use the Family Trainer Mat as an input device.
@ Family Trainer - Manhattan Police
@ Family Trainer - Meiro Daisakusen
@ Kamen Rider Club
@ Space Shadow
mapper70init:
@---------------------------------------------------------------------------------
	.word write70,write70,write70,write70
	bx lr
@---------------------------------------------------------------------------------
@ Bandai mapper 152, mirroring
@ Arkanoid 2 (J)
@ Gegege no Kitarou 2
@ Saint Seiya ..
mapper152init:
@---------------------------------------------------------------------------------
	.word write152,write152,write152,write152

	movs r0,#1
	b mirror1_
@---------------------------------------------------------------------------------
write70:
@---------------------------------------------------------------------------------
	stmfd sp!,{r0,lr}
	bl chr01234567_
	ldmfd sp!,{r0,lr}
	mov r0,r0,lsr#4
	b map89AB_
@---------------------------------------------------------------------------------
write152:
@---------------------------------------------------------------------------------
	mov addy,r0,lsr#4
	stmfd sp!,{addy,lr}
	bl chr01234567_
	tst addy,#0x8
	bl mirror1_
	ldmfd sp!,{r0,lr}
	b map89AB_
@---------------------------------------------------------------------------------
