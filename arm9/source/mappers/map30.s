;@----------------------------------------------------------------------------
	#include "equates.h"
;@----------------------------------------------------------------------------
	.global mapper30init
;@----------------------------------------------------------------------------
.section .text,"ax"
;@----------------------------------------------------------------------------
;@ RetroUSB UNROM 512
;@ Uses bankable CHR RAM.
mapper30init:
;@----------------------------------------------------------------------------
	.word mapper30Write,mapper30Write,mapper30Write,mapper30Write
	bx lr

mapper30Write:
	stmfd sp!,{r0,lr}
	bl map89AB_
	ldmfd sp,{r0}
	mov r0,r0,lsr#5
	and r0,r0,#3
	bl chr01234567_			;@ This should use VRAM
	ldmfd sp!,{r0,lr}
	tst r0,#0x80
	b mirror1_
