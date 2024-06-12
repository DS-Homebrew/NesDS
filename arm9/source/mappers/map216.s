@---------------------------------------------------------------------------------
	#include "equates.h"
@---------------------------------------------------------------------------------
	.global mapper216init
@---------------------------------------------------------------------------------
.section .text,"ax"
@---------------------------------------------------------------------------------
@ Russian mapper (by RCM Group?)
@ Used in:
@ Bonza
@ Videopoker Bonza
@ Magic Jewelry II
mapper216init:
@---------------------------------------------------------------------------------
	.word write, write, write, write

	stmfd sp!, {lr}
	mov r0, #0
	bl map89ABCDEF_
	ldmfd sp!, {lr}
	mov r0, #0
	b chr01234567_

write:
	stmfd sp!, {lr}
	mov r0, addy, lsr#1
	and r0, r0, #0xE
	bl chr01234567_
	ldmfd sp!, {lr}
	and r0, addy, #1
	b map89ABCDEF_
